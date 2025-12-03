event void FDarkMassAttachSignature(ADarkMassActor MassActor, FDarkMassSurfaceData SurfaceData);
event void FDarkMassGrabSignature(ADarkMassActor MassActor, FDarkMassGrabData GrabData);

class UDarkMassResponseComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	FDarkMassAttachSignature OnAttach;
	FDarkMassAttachSignature OnDetach;
	FDarkMassGrabSignature OnGrabbed;
	FDarkMassGrabSignature OnReleased;

	void Attach(ADarkMassActor MassActor,
		FDarkMassSurfaceData SurfaceData)
	{
		OnAttach.Broadcast(MassActor, SurfaceData);
	}

	void Detach(ADarkMassActor MassActor,
		FDarkMassSurfaceData SurfaceData)
	{
		OnDetach.Broadcast(MassActor, SurfaceData);
	}

	void Grab(ADarkMassActor MassActor,
		FDarkMassGrabData GrabData)
	{
		OnGrabbed.Broadcast(MassActor, GrabData);
	}

	void Release(ADarkMassActor MassActor,
		FDarkMassGrabData GrabData)
	{
		OnReleased.Broadcast(MassActor, GrabData);
	}
}