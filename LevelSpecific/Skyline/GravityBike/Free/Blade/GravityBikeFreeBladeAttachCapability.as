enum EGravityBikeFreeBladeAttachment
{
	Back,
	Detached,
};

class UGravityBikeFreeBladeAttachCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	UGravityBikeFreeBladePlayerComponent BladeComp;
	EGravityBikeFreeBladeAttachment Attachment = EGravityBikeFreeBladeAttachment::Detached;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BladeComp = UGravityBikeFreeBladePlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(BladeComp.BladeActor.bIsControlledByCutscene)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(BladeComp.BladeActor.bIsControlledByCutscene)
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
		if(Attachment != EGravityBikeFreeBladeAttachment::Detached)
			Detach();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UpdateAttachment();
	}

	void UpdateAttachment()
	{
		EGravityBikeFreeBladeAttachment DesiredAttachment = GetDesiredAttachment();
		if(Attachment == DesiredAttachment)
		{
			if(Attachment != EGravityBikeFreeBladeAttachment::Detached)
			{
				BladeComp.BladeActor.SetActorRelativeTransform(FTransform::Identity);
			}
			
			return;
		}

		switch(DesiredAttachment)
		{
			case EGravityBikeFreeBladeAttachment::Back:
				AttachToBack();
				break;

			case EGravityBikeFreeBladeAttachment::Detached:
				Detach();
				break;
		}
	}

	EGravityBikeFreeBladeAttachment GetDesiredAttachment() const
	{
		return EGravityBikeFreeBladeAttachment::Back;
	}

	void AttachToBack()
	{
		BladeComp.BladeActor.AttachToComponent(Player.Mesh, n"GravityBladeSocket");
		Attachment = EGravityBikeFreeBladeAttachment::Back;
	}

	void Detach()
	{
		if(BladeComp.BladeActor.AttachParentActor == Player)
		{
			BladeComp.BladeActor.DetachFromActor(EDetachmentRule::KeepWorld,EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		}

		Attachment = EGravityBikeFreeBladeAttachment::Detached;
	}
};