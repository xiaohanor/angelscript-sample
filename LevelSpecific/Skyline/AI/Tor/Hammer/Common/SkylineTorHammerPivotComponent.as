class USkylineTorHammerPivotComponent : USceneComponent
{
	ASkylineTorHammerPivot Pivot;
	USkylineTorHammerComponent HammerComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Pivot = ASkylineTorHammerPivot::Spawn();
		Pivot.MakeNetworked(this);
		HammerComp = USkylineTorHammerComponent::GetOrCreate(Owner);
	}

	void SetPivot(FVector PivotLocation)
	{
		HammerComp.ResetTranslations();
		RemovePivot();
		Pivot.ActorLocation = PivotLocation;
		Pivot.ActorRotation = Owner.ActorRotation;
		Owner.AttachToActor(Pivot, NAME_None, EAttachmentRule::KeepWorld);
	}

	void RemovePivot()
	{
		if(Owner.AttachParentActor == Pivot)
			Owner.DetachFromActor();
	}
}