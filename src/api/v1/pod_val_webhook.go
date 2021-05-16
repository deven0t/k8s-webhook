package v1

import (
	"context"
	"fmt"
	"net/http"

	"github.com/go-logr/logr"

	corev1 "k8s.io/api/core/v1"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/webhook/admission"
)

// +kubebuilder:webhook:admissionReviewVersions=v1,path=/validate,mutating=false,failurePolicy=fail,groups="",resources=pods,verbs=create;update,versions=v1,name=vpod.kb.io,sideEffects=none

// podValidator validates Pods
type podValidator struct {
	Client  client.Client
	decoder *admission.Decoder
	Log     logr.Logger
}

func NewPodValidator(c client.Client, log logr.Logger) admission.Handler {
	return &podValidator{Client: c, Log: log}
}

// podValidator admits a pod if a specific annotation exists.
func (v *podValidator) Handle(ctx context.Context, req admission.Request) admission.Response {
	pod := &corev1.Pod{}

	err := v.decoder.Decode(req, pod)
	if err != nil {
		return admission.Errored(http.StatusBadRequest, err)
	}
	log := v.Log.WithValues("kind", pod.Kind, "name", pod.Name, "namespace", pod.Namespace)
	log.Info("Received request for validation")
	key := "block"
	value := "me"
	anno, found := pod.Annotations[key]
	if found && anno == value {
		return admission.Denied(fmt.Sprintf("Blocking due to annotation %s", key))
	}
	return admission.Allowed("")
}

// podValidator implements admission.DecoderInjector.
// A decoder will be automatically injected.

// InjectDecoder injects the decoder.
func (v *podValidator) InjectDecoder(d *admission.Decoder) error {
	v.decoder = d
	return nil
}
