
class UTrainPlayerLaunchOffCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::LastMovement;
	default SeparateInactiveTick(EHazeTickGroup::InfluenceMovement, 10);
	default CapabilityTags.Add(n"TrainLaunch");

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UTrainPlayerLaunchOffComponent LaunchOffComp;
	UPlayerTargetablesComponent TargetablesComp;
	UPlayerMovementComponent MoveComp;
	UPlayerInteractionsComponent InteractionsComp;
	USteppingMovementData Movement;

	FVector OffsetFromCart;
	FTrainPlayerLaunchParams Launch;
	bool bTrivialMovementBlocked = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LaunchOffComp = UTrainPlayerLaunchOffComponent::GetOrCreate(Player);
		TargetablesComp = UPlayerTargetablesComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		InteractionsComp = UPlayerInteractionsComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTrainPlayerLaunchParams& LaunchParams) const
	{
		if (!LaunchOffComp.bShouldLaunch)
			return false;

		if(InteractionsComp.ActiveInteraction != nullptr)
			return false;

		LaunchParams = LaunchOffComp.Launch;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		if (LaunchOffComp.bShouldLaunch)
			return true;
		if (ActiveDuration > Launch.ForceDuration + Launch.FloatDuration)
			return true;
		if (ActiveDuration > Launch.ForceDuration && MoveComp.IsOnWalkableGround())
			return true;
		if(InteractionsComp.ActiveInteraction != nullptr)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTrainPlayerLaunchParams LaunchParams)
	{
		LaunchOffComp.bShouldLaunch = false;
		LaunchOffComp.Launch = FTrainPlayerLaunchParams();

		Launch = LaunchParams;
		Launch.LaunchFromCart = Launch.LaunchFromCart.Driver.GetCartClosestToPlayer(Player);

		FTransform CartPosition = Launch.LaunchFromCart.CurrentPosition.WorldTransform;
		OffsetFromCart = CartPosition.InverseTransformPosition(Player.ActorLocation);

		MoveComp.FollowComponentMovement(Launch.LaunchFromCart.RootComponent, this, EMovementFollowComponentType::Teleport);
		BlockTrivialMovement();

		// Yank player out of interactions
		Player.DetachFromActor();
		auto PlayerInteractionsComp = UPlayerInteractionsComponent::Get(Player);
		if (PlayerInteractionsComp != nullptr)
				PlayerInteractionsComp.KickPlayerOutOfAnyInteraction();

		if (Launch.PointOfInterestDuration > 0.0)
		{
			auto Poi = Player.CreatePointOfInterest();

			// The PoI should go either to the closest grapple point, or to the cart
			/*auto PrimaryGrapple = TargetablesComp.GetPrimaryTarget(UGrapplePointBaseComponent);
			if (PrimaryGrapple != nullptr)
			{
				Poi.FocusTarget.Component = PrimaryGrapple;
			}
			else*/
			{
				auto ClosestCart = Launch.LaunchFromCart.Driver.GetCartClosestToPlayer(Player);
				Poi.FocusTarget.SetFocusToComponent(ClosestCart.Root);
				//Poi.FocusTarget.LocalOffset.Z = 500.0;
				Poi.FocusTarget.LocalOffset = FVector(ClosestCart.ActorTransform.InverseTransformPosition(Player.ActorLocation).X + 200.0, 0, 0);
			}

			Poi.Settings.ClearOnInput = CameraPOIDefaultClearOnInput;
			Poi.Settings.Duration = Launch.PointOfInterestDuration;
			Poi.Apply(this, 1);
		}
	}

	void BlockTrivialMovement()
	{
		if (bTrivialMovementBlocked)
			return;

		bTrivialMovementBlocked = true;

		// We want to be able to be interrupted by grappling and other advanced movement,
		// but trivial stuff such as dashing and jumping should not cancel the launch.
		Player.BlockCapabilities(PlayerMovementTags::Dash, this);
		Player.BlockCapabilities(PlayerMovementTags::Jump, this);
		Player.BlockCapabilities(PlayerMovementTags::LedgeGrab, this);
		Player.BlockCapabilities(PlayerMovementTags::Slide, this);
		Player.BlockCapabilities(CoastBossTags::CoastBossTag, this);
	}

	void UnblockTrivialMovement()
	{
		if (!bTrivialMovementBlocked)
			return;

		bTrivialMovementBlocked = false;
		Player.UnblockCapabilities(PlayerMovementTags::Dash, this);
		Player.UnblockCapabilities(PlayerMovementTags::Jump, this);
		Player.UnblockCapabilities(PlayerMovementTags::LedgeGrab, this);
		Player.UnblockCapabilities(PlayerMovementTags::Slide, this);
		Player.UnblockCapabilities(CoastBossTags::CoastBossTag, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearPointOfInterestByInstigator(this);
		MoveComp.UnFollowComponentMovement(this);
		UnblockTrivialMovement();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				Movement.AddPendingImpulses();

				if (ActiveDuration < Launch.ForceDuration)
				{
					Movement.BlockStepDownForThisFrame();
					Movement.BlockStepUpForThisFrame();

					Movement.AddVelocity(Launch.Force);
				}
				else
				{
					float ForceAlpha = Math::Pow(1.0 - Math::Clamp((ActiveDuration - Launch.ForceDuration) / Launch.FloatDuration, 0.0, 0.9), 1.0);
					Movement.AddVelocity(Launch.Force * ForceAlpha);

					if (bTrivialMovementBlocked)
						UnblockTrivialMovement();
				}
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"AirMovement");
		}
	}
};

class UTrainPlayerLaunchOffMarkerCapability : UHazeMarkerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	AHazePlayerCharacter Player;
	UTrainPlayerLaunchOffComponent LaunchComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		LaunchComp = UTrainPlayerLaunchOffComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerBlocked()
	{
		LaunchComp.AddLaunchBlocker(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerUnblocked()
	{
		LaunchComp.RemoveLaunchBlocker(this);
	}
}

struct FTrainPlayerLaunchParams
{
	ACoastTrainCart LaunchFromCart;
	FVector Force;
	float ForceDuration = 0.0;
	float FloatDuration = 0.0;
	float PointOfInterestDuration = 0.0;
};

class UTrainPlayerLaunchOffComponent : UActorComponent
{
	access Capability = private, UTrainPlayerLaunchOffCapability;

	access:Capability bool bShouldLaunch = false;
	access:Capability FTrainPlayerLaunchParams Launch;
	private TArray<FInstigator> Blockers;

	void TryLaunch(FTrainPlayerLaunchParams In_Launch)
	{
		if(IsLaunchBlocked())
			return;

		bShouldLaunch = true;
		Launch = In_Launch;
	}

	void AddLaunchBlocker(FInstigator Instigator)
	{
		Blockers.AddUnique(Instigator);
	}

	void RemoveLaunchBlocker(FInstigator Instigator)
	{
		Blockers.RemoveSingleSwap(Instigator);
	}

	bool IsLaunchBlocked() const
	{
		return Blockers.Num() > 0;
	}
}