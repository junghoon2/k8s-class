package model

import (
	"github.com/grafana-operator/grafana-operator/v4/controllers/constants"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"sigs.k8s.io/controller-runtime/pkg/client"

	"github.com/grafana-operator/grafana-operator/v4/api/integreatly/v1alpha1"
)

func getPVCLabels(cr *v1alpha1.Grafana) map[string]string {
	if cr.Spec.DataStorage == nil {
		return nil
	}
	return cr.Spec.DataStorage.Labels
}

func getPVCAnnotations(cr *v1alpha1.Grafana, existing map[string]string) map[string]string {
	if cr.Spec.DataStorage == nil {
		return existing
	}

	return MergeAnnotations(cr.Spec.DataStorage.Annotations, existing)
}

func getStorageClass(cr *v1alpha1.Grafana) *string {
	if cr.Spec.DataStorage == nil || cr.Spec.DataStorage.Class == "" {
		return nil
	}

	return &cr.Spec.DataStorage.Class
}

func getVolumeName(cr *v1alpha1.Grafana) string {
	if cr.Spec.DataStorage == nil {
		return ""
	}

	return cr.Spec.DataStorage.VolumeName
}

func getPVCSpec(cr *v1alpha1.Grafana) corev1.PersistentVolumeClaimSpec {
	return corev1.PersistentVolumeClaimSpec{
		AccessModes: cr.Spec.DataStorage.AccessModes,
		Resources: corev1.ResourceRequirements{
			Requests: corev1.ResourceList{
				corev1.ResourceStorage: cr.Spec.DataStorage.Size,
			},
		},
		StorageClassName: getStorageClass(cr),
		VolumeName:       getVolumeName(cr),
	}
}

func GrafanaDataPVC(cr *v1alpha1.Grafana) *corev1.PersistentVolumeClaim {
	return &corev1.PersistentVolumeClaim{
		ObjectMeta: metav1.ObjectMeta{
			Name:        constants.GrafanaDataStorageName,
			Namespace:   cr.Namespace,
			Labels:      getPVCLabels(cr),
			Annotations: getPVCAnnotations(cr, nil),
		},
		Spec: getPVCSpec(cr),
	}
}

func GrafanaPVCReconciled(cr *v1alpha1.Grafana, currentState *corev1.PersistentVolumeClaim) *corev1.PersistentVolumeClaim {
	reconciled := currentState.DeepCopy()
	reconciled.Labels = getPVCLabels(cr)
	reconciled.Annotations = getPVCAnnotations(cr, currentState.Annotations)
	return reconciled
}

func GrafanaDataStorageSelector(cr *v1alpha1.Grafana) client.ObjectKey {
	return client.ObjectKey{
		Namespace: cr.Namespace,
		Name:      constants.GrafanaDataStorageName,
	}
}
