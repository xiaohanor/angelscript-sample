class UCoastTrainDroneCombatPositioningBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UCoastTrainDroneSettings DroneSettings;
	AHazePlayerCharacter PlayerTarget;

	ACoastTrainCart TrainCart;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		DroneSettings = UCoastTrainDroneSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (!TargetComp.Target.ActorCenterLocation.IsWithinDist(Owner.ActorCenterLocation, DroneSettings.CombatPositioningRange))
			return false;		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		if (!TargetComp.Target.ActorCenterLocation.IsWithinDist(Owner.ActorCenterLocation, DroneSettings.CombatPositioningRange * 1.3))
			return true;		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		PlayerTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);

		auto RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		if (RespawnComp != nullptr && RespawnComp.Spawner != nullptr && RespawnComp.Spawner.AttachParentActor != nullptr)
			TrainCart = Cast<ACoastTrainCart>(RespawnComp.Spawner.AttachParentActor);
		else if (Owner.AttachParentActor != nullptr)
			TrainCart = Cast<ACoastTrainCart>(Owner.AttachParentActor);
		else
			TrainCart = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector CombatLocation = PlayerTarget.ActorLocation;
		FVector OffsetDir = PlayerTarget.ActorForwardVector;
		OffsetDir = PlayerTarget.ViewRotation.ForwardVector.GetSafeNormal2D();
		CombatLocation += OffsetDir * DroneSettings.CombatPositioningRange * 0.15;
		CombatLocation.Z = GetLocationZ();

		if(!Owner.ActorLocation.IsWithinDist(CombatLocation, 300))
		{
			float Speed = DroneSettings.CombatPositioningSpeed * Math::Clamp((Owner.ActorLocation.Distance(CombatLocation) - 200.0) / 5000.0, 0.1, 1.0);
			DestinationComp.MoveTowards(CombatLocation, Speed);
		}
	}

	private float GetLocationZ()
	{
		float LocZ = PlayerTarget.ActorLocation.Z + DroneSettings.CombatPositioningHeight;

		if(TrainCart == nullptr)
			return LocZ;

		ACoastTrainCart PlayerTrainCart = TrainCart.Driver.GetCartClosestToPlayer(PlayerTarget);
		if(PlayerTrainCart == nullptr)
			return LocZ;

		float CartZ = PlayerTrainCart.ActorCenterLocation.Z;
		return Math::Clamp(LocZ, CartZ + DroneSettings.CombatPositioningCartMinHeight, CartZ + DroneSettings.CombatPositioningCartMaxHeight);
	}
}
