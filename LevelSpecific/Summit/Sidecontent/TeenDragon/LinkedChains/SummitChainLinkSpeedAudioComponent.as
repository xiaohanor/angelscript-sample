class USummitChainLinkSpeedAudioComponent : USceneComponent
{
	private float Speed;
	FVector PreviousLocation;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Speed = (WorldLocation - PreviousLocation).Size() / DeltaSeconds;
		PreviousLocation = WorldLocation;
	}

	UFUNCTION(BlueprintPure)
	float GetSpeed() const
	{
		return Speed;
	}

	void AttachToLink(ASummitChainLink NewLink)
	{
		AttachToComponent(NewLink.MeshComp, AttachmentRule = EAttachmentRule::SnapToTarget);
		PreviousLocation = NewLink.PreviousLocation;
		NewLink.AudioComp = this;
	}

	void DestroyAudioComp()
	{
		BP_PreDestroyed();
		DestroyComponent(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_PreDestroyed() {}
};