
class UPlayerLandingStunnedCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	
	default CapabilityTags.Add(n"GroundMovement");
	default CapabilityTags.Add(n"Landing");

	default DebugCategory = n"Movement";

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 10;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerLandingComponent LandingComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		LandingComp = UPlayerLandingComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (MoveComp.IsFalling())
		{
			const float StunnedSpeedFraction = -Player.GetActorVelocity().Z / LandingComp.Settings.Stunned.Speed;
			const float StunnedDistanceFraction = Math::Abs((MoveComp.FallingData.StartLocation - Player.ActorLocation).DotProduct(MoveComp.WorldUp)) / LandingComp.Settings.Stunned.Distance;

			LandingComp.AnimData.StunnedFraction = Math::Clamp(Math::Min(StunnedSpeedFraction, StunnedDistanceFraction), 0.0, 1.0);

			const float FatalSpeedFraction = -Player.GetActorVelocity().Z / LandingComp.Settings.Fatal.Speed;
			const float FatalDistanceFraction = Math::Abs((MoveComp.FallingData.StartLocation - Player.ActorLocation).DotProduct(MoveComp.WorldUp)) / LandingComp.Settings.Fatal.Distance;
			
			LandingComp.AnimData.FatalFraction = Math::Clamp(Math::Min(FatalSpeedFraction, FatalDistanceFraction), 0.0, 1.0);
		}
		else
		{
			LandingComp.AnimData.StunnedFraction = 0.0;
			LandingComp.AnimData.FatalFraction = 0.0;

		}

	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (MoveComp.IsInAir())
			return false;

		if (!MoveComp.WasFalling())
			return false;

		if (LandingComp.InstigatedStunnedLandingMode.Get() == EPlayerLandingMode::Avoid)
			return false;
		if (LandingComp.InstigatedStunnedLandingMode.Get() == EPlayerLandingMode::Force)
			return true;

		const float LandSpeed = -MoveComp.WorldUp.DotProduct(MoveComp.FallingData.EndVelocity);
		if (LandSpeed < LandingComp.Settings.Stunned.Speed)
			return false;
		
		const FVector ToLandLocation = MoveComp.FallingData.EndLocation - MoveComp.FallingData.StartLocation;
		const float Distance = Math::Abs(ToLandLocation.DotProduct(MoveComp.WorldUp));
		if (Distance < LandingComp.Settings.Stunned.Distance)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (ActiveDuration >= LandingComp.Settings.StunnedDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		LandingComp.AnimData.State = EPlayerLandingState::Stunned;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{	
				Movement.AddGravityAcceleration();
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Landing");
		}
	}
}