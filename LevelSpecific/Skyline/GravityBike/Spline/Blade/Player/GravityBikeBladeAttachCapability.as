enum EGravityBikeBladeAttachment
{
	Hip,
	Hand,
	Detached,
};

class UGravityBikeBladeAttachCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	UGravityBikeBladePlayerComponent BladeComp;
	EGravityBikeBladeAttachment Attachment = EGravityBikeBladeAttachment::Detached;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BladeComp = UGravityBikeBladePlayerComponent::Get(Player);
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
		if(Attachment != EGravityBikeBladeAttachment::Detached)
			Detach();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UpdateAttachment();
	}

	void UpdateAttachment()
	{
		EGravityBikeBladeAttachment DesiredAttachment = GetDesiredAttachment();
		if(Attachment == DesiredAttachment)
		{
			if(Attachment != EGravityBikeBladeAttachment::Detached)
			{
				BladeComp.BladeActor.SetActorRelativeTransform(FTransform::Identity);
			}
			
			return;
		}

		switch(DesiredAttachment)
		{
			case EGravityBikeBladeAttachment::Hip:
				AttachToHip();
				break;

			case EGravityBikeBladeAttachment::Hand:
				AttachToHand();
				break;

			case EGravityBikeBladeAttachment::Detached:
				Detach();
				break;
		}
	}

	EGravityBikeBladeAttachment GetDesiredAttachment() const
	{
		switch(BladeComp.State)
		{
			case EGravityBikeBladeState::None:
			{
				if(BladeComp.HasThrowTarget())
					return EGravityBikeBladeAttachment::Hand;
				else
					return EGravityBikeBladeAttachment::Hip;
			}

			case EGravityBikeBladeState::Throwing:
				return EGravityBikeBladeAttachment::Hand;

			case EGravityBikeBladeState::Thrown:
				return EGravityBikeBladeAttachment::Detached;

			case EGravityBikeBladeState::Grappling:
				return EGravityBikeBladeAttachment::Detached;

			case EGravityBikeBladeState::Barrel:
				return EGravityBikeBladeAttachment::Detached;
		}
	}

	void AttachToHip()
	{
		//BladeComp.BladeActor.OffsetComp.FreezeTransformAndLerpBackToParent(this, 0.2);
		BladeComp.BladeActor.AttachToComponent(Player.Mesh, GravityBikeBlade::HipSocket);
		Attachment = EGravityBikeBladeAttachment::Hip;
	}

	void AttachToHand()
	{
		//BladeComp.BladeActor.OffsetComp.FreezeTransformAndLerpBackToParent(this, 0.2);
		BladeComp.BladeActor.AttachToComponent(Player.Mesh, GravityBikeBlade::HandSocket);
		BladeComp.BladeActor.SetActorRotation(FQuat::MakeFromZX(-BladeComp.BladeActor.ActorRightVector, BladeComp.BladeActor.ActorUpVector));
		Attachment = EGravityBikeBladeAttachment::Hand;
	}

	void Detach()
	{
		if(BladeComp.BladeActor.AttachParentActor == Player)
		{
			BladeComp.BladeActor.DetachFromActor(EDetachmentRule::KeepWorld,EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		}

		Attachment = EGravityBikeBladeAttachment::Detached;
	}
};