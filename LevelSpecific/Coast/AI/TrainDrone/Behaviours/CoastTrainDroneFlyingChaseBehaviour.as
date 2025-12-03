
// Move towards enemy
class UCoastTrainDroneFlyingChaseBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UCoastTrainDroneSettings DroneSettings;

	ACoastTrainCart TrainCart;
	AHazePlayerCharacter PlayerTarget;

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
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.HasValidTarget())
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
		FVector ChaseLocation = PlayerTarget.ActorLocation;
		ChaseLocation.Z = GetLocationZ();

		if (Owner.ActorLocation.IsWithinDist(ChaseLocation, BasicSettings.ChaseMinRange))
		{
			Cooldown.Set(0.5);
			return;
		}

		// Keep moving towards target!
		DestinationComp.MoveTowards(ChaseLocation, BasicSettings.ChaseMoveSpeed);
	}

	private float GetLocationZ()
	{
		float LocZ = PlayerTarget.ActorLocation.Z + BasicSettings.FlyingChaseHeight;

		if(TrainCart == nullptr)
			return LocZ;

		ACoastTrainCart PlayerTrainCart = TrainCart.Driver.GetCartClosestToPlayer(PlayerTarget);
		if(PlayerTrainCart == nullptr)
			return LocZ;

		float CartZ = PlayerTrainCart.ActorCenterLocation.Z;
		return Math::Clamp(LocZ, CartZ + DroneSettings.CombatPositioningCartMinHeight, CartZ + DroneSettings.CombatPositioningCartMaxHeight);
	}
}