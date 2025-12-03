class USketchbookRidingGoatPlayerCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	USketchbookGoatPlayerComponent PlayerComp;
	UPlayerMovementComponent MoveComp;
	UTeleportResponseComponent TeleportComp;

	ASketchbookGoat GoatToMount;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = USketchbookGoatPlayerComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		TeleportComp = UTeleportResponseComponent::GetOrCreate(Player);
	}
	
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PlayerComp.MountedGoat == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(CanDismount())
			return true;

		return false;
	}

	bool CanDismount() const
	{
		if(!PlayerComp.bWaitingDismount)
			return false;
		
		if(PlayerComp.MountedGoat.GetGoatSplineMoveComp().IsInAir())
			return false;

		if(!PlayerComp.MountedGoat.GetOtherGoat().IsMounted())
		{
			if(Math::Abs(PlayerComp.MountedGoat.GetOtherGoat().ActorLocation.Y - PlayerComp.MountedGoat.ActorLocation.Y) < 100)
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Apply(false, this, EInstigatePriority::High);
		TeleportComp.OnTeleported.AddUFunction(this, n"OnTeleported");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(PlayerComp.HasMountedGoat())
			PlayerComp.DismountGoat();

		MoveComp.ActiveConstrainRotationToHorizontalPlane.Clear(this);
		TeleportComp.OnTeleported.Unbind(this, n"OnTeleported");
	}

	UFUNCTION()
	private void OnTeleported()
	{
		PlayerComp.MountedGoat.SetActorTransform(Player.ActorTransform);
		Player.SetActorRelativeTransform(FTransform::Identity);
	}
};