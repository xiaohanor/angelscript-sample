class UGravityBikeWhipAttachCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	UGravityBikeWhipComponent WhipComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WhipComp = UGravityBikeWhipComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(WhipComp.WhipActor.bIsControlledByCutscene)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(WhipComp.WhipActor.bIsControlledByCutscene)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UpdateAttachment();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Detach();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UpdateAttachment();
	}

	void UpdateAttachment()
	{
		if(WhipComp.bIsHolstered)
			AttachToHip();
		else
			AttachToHand();
	}

	void AttachToHip()
	{
		if(WhipComp.WhipActor.AttachParentSocketName != GravityWhip::Common::IdleAttachSocket)
		{
			WhipComp.WhipActor.AttachToComponent(Player.Mesh, GravityWhip::Common::IdleAttachSocket);
			WhipComp.WhipActor.SetActorRelativeTransform(GravityWhip::Common::IdleAttachTransform);
		}
	}

	void AttachToHand()
	{
		if(WhipComp.WhipActor.AttachParentSocketName != GravityWhip::Common::AttachSocket)
		{
			WhipComp.WhipActor.AttachToComponent(Player.Mesh, GravityWhip::Common::AttachSocket);
		}
	}

	void Detach()
	{
		if(WhipComp.WhipActor.AttachParentActor == Player)
			WhipComp.WhipActor.DetachFromActor(EDetachmentRule::KeepWorld,EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
	}
};