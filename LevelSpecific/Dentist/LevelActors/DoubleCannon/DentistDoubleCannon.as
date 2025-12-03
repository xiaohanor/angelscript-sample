event void FDentistDoubleCannonOnPlayersEntered();
event void FDentistDoubleCannonOnPlayersLaunched();
event void FDentistDoubleCannonOnPlayersDetached();

asset DentistDoubleCannonSheet of UHazeCapabilitySheet
{
	Capabilities.Add(UDentistDoubleCannonAimingCapability);
	Capabilities.Add(UDentistDoubleCannonLaunchingCapability);
	Capabilities.Add(UDentistDoubleCannonMoveLaunchedRootCapability);
	Capabilities.Add(UDentistDoubleCannonResettingCapability);
};

enum EDentistDoubleCannonState
{
	Inactive,
	Aiming,
	Launching,
	Resetting,
};
struct FDentistDoubleCannonPlayerState
{
	float GroundPoundTime = -1.0;
};

UCLASS(Abstract)
class ADentistDoubleCannon : AHazeActor
{
	access Launch = private, UDentistDoubleCannonLaunchingCapability;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeMovablePlayerTriggerComponent PlayerTriggerComp;
	default PlayerTriggerComp.Shape = FHazeShapeSettings::MakeCapsule(250, 500);
	default PlayerTriggerComp.RelativeLocation = FVector(0, 0, 750);

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent YawPivotComp;

	UPROPERTY(DefaultComponent, Attach = YawPivotComp)
	UStaticMeshComponent HingeMeshComp;

	UPROPERTY(DefaultComponent, Attach = YawPivotComp)
	USceneComponent PitchPivotComp;

	UPROPERTY(DefaultComponent, Attach = PitchPivotComp)
	USceneComponent SpringTopComp;

	UPROPERTY(DefaultComponent, Attach = SpringTopComp)
	UFauxPhysicsTranslateComponent SpringTranslateComp;

	UPROPERTY(DefaultComponent, Attach = SpringTranslateComp)
	UStaticMeshComponent SpringTopMeshComp;

	UPROPERTY(DefaultComponent, Attach = SpringTranslateComp)
	USceneComponent ToothAttachmentComp;

	UPROPERTY(DefaultComponent, Attach = PitchPivotComp)
	USceneComponent BarrelRootComp;

	UPROPERTY(DefaultComponent, Attach = BarrelRootComp)
	UStaticMeshComponent BarrelMeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultSheets.Add(DentistDoubleCannonSheet);

	UPROPERTY(DefaultComponent)
	UDentistToothMovementResponseComponent MovementResponseComp;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComp;
	default MovementImpactCallbackComp.bTriggerLocally = true;
	default MovementImpactCallbackComp.bUseSpecifiedComponentsForImpacts = true;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent PlayerWeightComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	UPROPERTY(EditAnywhere, Category = "Triggering")
	float MaxTimeSinceGroundPound = 1.0;

	UPROPERTY(EditAnywhere, Category = "Triggering")
	float MaxHorizontalDistance = 250;

	UPROPERTY(EditAnywhere, Category = "Triggering")
	float MaxVerticalDistance = 200;

	UPROPERTY(EditAnywhere, Category = "Triggering")
	float GroundPoundImpulse = 500;

	UPROPERTY(EditAnywhere, Category = "Aiming")
	float AimRotateDuration = 2;
	
	UPROPERTY(EditAnywhere, Category = "Aiming")
	FVector2D RotationAlphaRange = FVector2D(0.5, 1.0);

	UPROPERTY(EditAnywhere, Category = "Aiming")
	FVector2D LocationAlphaRange = FVector2D(0.0, 0.7);

	UPROPERTY(EditInstanceOnly, Category = "Aiming|Initial", Meta = (ClampMin = "-180.0", ClampMax = "180.0"))
	float InitialYaw;

	UPROPERTY(EditInstanceOnly, Category = "Aiming|Initial", Meta = (ClampMin = "-180.0", ClampMax = "180.0"))
	float InitialPitch;

	UPROPERTY(EditInstanceOnly, Category = "Aiming|Target", Meta = (ClampMin = "0", ClampMax = "1000"))
	ADentistDoubleCannonTarget AimAtTarget = nullptr;

	UPROPERTY(EditInstanceOnly, Category = "Aiming|Target", Meta = (EditCondition = "AimAtTarget != nullptr", EditConditionHides, ClampMin = "0.1", ClampMax = "20.0"))
	float FlyToAimAtTargetDuration = 5;

	UPROPERTY(EditInstanceOnly, Category = "Aiming|Target", Meta = (ClampMin = "0", UIMax = "1000"))
	float TargetCannonHeight = 200;

#if EDITOR
	UPROPERTY(EditInstanceOnly, Transient, Category = "Aiming|Preview", Meta = (ClampMin = "0.0", ClampMax = "1.0"))
	float PreviewAlpha = 0.0;
#endif

	UPROPERTY(EditInstanceOnly, Category = "Aiming|Camera")
	AHazeCameraActor CameraToActivateWhileAiming = nullptr;

	UPROPERTY(EditInstanceOnly, Category = "Aiming|Camera", Meta = (EditCondition = "CameraToActivateWhileAiming != nullptr", EditConditionHides))
	float CameraBlendInTime = 2.0;
	
	UPROPERTY(EditInstanceOnly, Category = "Aiming|Camera", Meta = (EditCondition = "CameraToActivateWhileAiming != nullptr", EditConditionHides))
	float CameraBlendOutTime = 3.0;

	UPROPERTY(EditAnywhere, Category = "Launch", Meta = (EditCondition = "AimAtTarget == nullptr"))
	float LaunchSpeed = 1000;

	UPROPERTY(EditInstanceOnly, Category = "Launch")
	ADentistDoubleCannonLaunchedRoot LaunchedRoot;

	UPROPERTY(EditAnywhere, Category = "Launch")
	float Gravity = 3000;

	// How long to wait after aiming is finished before we launch the player
	UPROPERTY(EditAnywhere, Category = "Launch")
	float LaunchDelay = 0.5;

	// How fast to play back the trajectory
	UPROPERTY(EditAnywhere, Category = "Launch")
	float LaunchPlayRate = 1;

	UPROPERTY(EditAnywhere, Category = "Launch|Rotation")
	UCurveFloat RotationAlphaUntilDetach;

	UPROPERTY(EditAnywhere, Category = "Launch|Rotation")
	int Rotations = 2;

	/**
	 * When along the launch should the players detach from the attachment, and continue on their own?
	 * This is basically required for network, as we want some time to allow the remote player to return to replicated movement.-
	 */
	UPROPERTY(EditAnywhere, Category = "Launch", Meta = (ClampMin = "0.0", ClampMax = "1.0"))
	float DetachAlpha = 0.7;

	// How long it takes after a launch to start resetting
	UPROPERTY(EditAnywhere, Category = "Reset")
	float ResetDelay = 1.0;

	// How long it takes to reset back to the initial rotation, and allow another enter
	UPROPERTY(EditAnywhere, Category = "Reset")
	float ResetDuration = 1.0;

	UPROPERTY(BlueprintReadOnly)
	FDentistDoubleCannonOnPlayersEntered OnPlayersEntered;

	UPROPERTY(BlueprintReadOnly)
	FDentistDoubleCannonOnPlayersLaunched OnPlayersLaunched;

	UPROPERTY(BlueprintReadOnly)
	FDentistDoubleCannonOnPlayersDetached OnPlayersDetached;

	private TPerPlayer<FDentistDoubleCannonPlayerState> PlayerStates;
	private EDentistDoubleCannonState State = EDentistDoubleCannonState::Inactive;

	private float TargetYaw = 90;
	private float TargetPitch = 45;

	access:Launch FTraversalTrajectory LaunchTrajectory;
	private float LaunchStartTime;
	
	float ResetStartTime;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		FRotator AimAtRotation = FRotator::MakeFromXZ(GetLaunchDirection(), FVector::UpVector);
		FRotator RelativeRotation = ActorTransform.InverseTransformRotation(AimAtRotation);
		TargetPitch = -(90 - RelativeRotation.Pitch);
		TargetYaw = RelativeRotation.Yaw;

		SetCannonAlpha(PreviewAlpha);

		if(LaunchedRoot != nullptr && !Dentist::DoubleCannon::bVisualizeWithActor)
		{
			auto Trajectory = GetLaunchTrajectory();
			// Place the LaunchedRoot actor at the cannon, just to keep it somewhere reasonable after using it in visualizations...
			LaunchedRoot.SetActorTransform(GetLaunchedRootTransformAtTime(Trajectory, 0.1));
			for(int i = 0; i < int(EHazePlayer::MAX); i++)
			{
				EHazePlayer Player = EHazePlayer(i);
				LaunchedRoot.GetAttachmentForPlayer(Player).SetWorldTransform(GetPlayerTransformAtTime(Trajectory, 0.1, Player, false));
			}
		}
	}

	void UpdateAiming()
	{
		FRotator AimAtRotation = FRotator::MakeFromXZ(GetLaunchDirection(), FVector::UpVector);
		FRotator RelativeRotation = ActorTransform.InverseTransformRotation(AimAtRotation);
		TargetPitch = -(90 - RelativeRotation.Pitch);
		TargetYaw = RelativeRotation.Yaw;

		SetCannonAlpha(PreviewAlpha);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetCannonAlpha(0);

		PlayerTriggerComp.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		PlayerTriggerComp.OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");

		MovementResponseComp.OnGroundPoundedOn.AddUFunction(this, n"OnGroundPoundedOn");

		MovementImpactCallbackComp.AddComponentUsedForImpacts(SpringTopMeshComp);
		MovementImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"OnGroundImpactedByPlayer");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		for(int i = 0; i < int(EHazePlayer::MAX); i++)
		{
			AHazePlayerCharacter Player = Game::Players[i];
			TemporalLog.Value(f"{Player.GetActorNameOrLabel()};PlayerState;GroundPoundTime", PlayerStates[Player].GroundPoundTime);
			TemporalLog.Value(f"{Player.GetActorNameOrLabel()};PlayerState;HasPlayerRecentlyGroundPounded", HasPlayerRecentlyGroundPounded(Player));
			TemporalLog.Value(f"{Player.GetActorNameOrLabel()};PlayerState;IsPlayerWithinBarrel", IsPlayerWithinBarrel(Player));
		}

		TemporalLog.Value("State", State);
		TemporalLog.Value("Launch Start Time", LaunchStartTime);
		TemporalLog.Value("Reset Start Time", ResetStartTime);
		TemporalLog.Value("HasBothPlayersRecentlyGroundPounded()", HasBothPlayersRecentlyGroundPounded());
		TemporalLog.Value("AreBothPlayersWithinTheBarrel()", AreBothPlayersWithinTheBarrel());
		TemporalLog.Value("CanEnterCannon()", CanEnterCannon());
		TemporalLog.Value("GetPredictedTimeSinceLaunchStart()", GetPredictedTimeSinceLaunchStart());
#endif
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		if(State != EDentistDoubleCannonState::Inactive)
			return;

		if(PlayerTriggerComp.PlayersInTrigger.Num() == 1)
		{
			FDentistDoubleCannonOnFirstPlayerEnterSpringEventData EventData;
			EventData.Player = Player;
			UDentistDoubleCannonEventHandler::Trigger_OnFirstPlayerEnterSpring(this, EventData);
		}
	}

	UFUNCTION()
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		if(State != EDentistDoubleCannonState::Inactive)
			return;

		if(!PlayerTriggerComp.AreAnyPlayersInTrigger())
		{
			FDentistDoubleCannonOnAllPlayersExitedSpringEventData EventData;
			EventData.Player = Player;
			UDentistDoubleCannonEventHandler::Trigger_OnAllPlayersExitedSpring(this, EventData);
		}
	}

	UFUNCTION()
	private void OnGroundPoundedOn(AHazePlayerCharacter GroundPoundPlayer, FHitResult Impact)
	{
		PlayerStates[GroundPoundPlayer].GroundPoundTime = Time::PredictedGlobalCrumbTrailTime;
		SpringTranslateComp.ApplyImpulse(Impact.ImpactPoint, SpringTranslateComp.UpVector * -GroundPoundImpulse);

		FDentistDoubleCannonOnPlayerGroundPoundLandEventData EventData;
		EventData.Player = GroundPoundPlayer;
		EventData.Impact = Impact;
		UDentistDoubleCannonEventHandler::Trigger_OnPlayerGroundPoundLand(this, EventData);
	}

	UFUNCTION()
	private void OnGroundImpactedByPlayer(AHazePlayerCharacter Player)
	{
		auto JumpComp = UDentistToothJumpComponent::Get(Player);
		if(!JumpComp.IsJumping())
			return;
		
		auto GroundPoundComp = UDentistToothGroundPoundComponent::Get(Player);
		if(GroundPoundComp.IsGroundPounding())
			return;

		FDentistDoubleCannonOnPlayerJumplandEventData EventData;
		EventData.Player = Player;
		UDentistDoubleCannonEventHandler::Trigger_OnPlayerJumpLand(this, EventData);
	}

	bool HasBothPlayersRecentlyGroundPounded() const
	{
		for(auto Player : Game::Players)
		{
			if(!HasPlayerRecentlyGroundPounded(Player))
				return false;
		}

		return true;
	}

	bool HasPlayerRecentlyGroundPounded(const AHazePlayerCharacter Player) const
	{
		auto PlayerState = PlayerStates[Player];

		if(PlayerState.GroundPoundTime < 0)
			return false;

		return (Time::PredictedGlobalCrumbTrailTime - PlayerState.GroundPoundTime) < MaxTimeSinceGroundPound;
	}

	bool AreBothPlayersWithinTheBarrel() const
	{
		for(auto Player : Game::Players)
		{
			if(!IsPlayerWithinBarrel(Player))
				return false;
		}

		return true;
	}

	bool IsPlayerWithinBarrel(const AHazePlayerCharacter Player) const
	{
		const FVector RelativeLocationToBarrelTop = SpringTopComp.WorldTransform.InverseTransformPositionNoScale(Player.ActorLocation);
		if(RelativeLocationToBarrelTop.Size2D() > 250)
			return false;

		if(RelativeLocationToBarrelTop.DotProduct(FVector::UpVector) > 200)
			return false;

		return true;
	}

	bool CanEnterCannon() const
	{
		if(State == EDentistDoubleCannonState::Resetting)
			return false;

		return true;
	}

	void StartAiming()
	{
		FRotator AimAtRotation = FRotator::MakeFromXZ(GetLaunchDirection(), FVector::UpVector);
		FRotator RelativeRotation = ActorTransform.InverseTransformRotation(AimAtRotation);
		TargetPitch = -(90 - RelativeRotation.Pitch);
		TargetYaw = RelativeRotation.Yaw;

		State = EDentistDoubleCannonState::Aiming;
	}

	void Launch(float LaunchTime)
	{
		LaunchTrajectory = CalculateLaunchTrajectory();
		State = EDentistDoubleCannonState::Launching;
		LaunchStartTime = LaunchTime;
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
	}

	float GetPredictedTimeSinceLaunchStart() const
	{
		return Time::PredictedGlobalCrumbTrailTime - LaunchStartTime;
	}

	FTransform GetLaunchedRootTransformAtTime(FTraversalTrajectory Trajectory, float Time) const
	{
		FVector Location = Trajectory.GetLocation(Time);
		FVector Direction = Trajectory.GetVelocity(Time).GetSafeNormal();

		const float DetachTime = Trajectory.GetTotalTime() * DetachAlpha;

		FQuat Rotation;
		if(Time < DetachTime)
		{
			float AlphaUntilDetach = Math::Saturate(Time / DetachTime);
			float RotationAlpha = RotationAlphaUntilDetach.GetFloatValue(AlphaUntilDetach) * Rotations;
			Rotation = FQuat::MakeFromZY(Direction, FQuat(Direction, RotationAlpha * PI * 2).ForwardVector);
		}
		else
		{
			Rotation = FQuat::MakeFromZY(Direction, FQuat(Direction, PI * 2).ForwardVector);
		}

		return FTransform(Rotation, Location);
	}

	FTransform GetPlayerTransformAtTime(FTraversalTrajectory Trajectory, float Time, EHazePlayer Player, bool bCenter) const
	{
		FTransform LaunchedRootTransform = GetLaunchedRootTransformAtTime(Trajectory, Time);
		FTransform PlayerOffset = LaunchedRoot.GetAttachmentRelativeTransformForPlayer(Player, true, bCenter);

		FTransform PlayerTransform = PlayerOffset * LaunchedRootTransform;

		const float DetachTime = Trajectory.GetTotalTime() * DetachAlpha;

		if(Time < DetachTime)
		{
			return PlayerTransform;
		}
		else
		{
			const float TimeFromDetach = Time - DetachTime;
			const float DurationFromDetachToLand = Trajectory.GetTotalTime() - DetachTime;
			float DetachTimeAlpha = Math::Saturate(TimeFromDetach / DurationFromDetachToLand);
			DetachTimeAlpha = Math::EaseIn(0, 1, DetachTimeAlpha, 2);

			FVector TargetLocation = AimAtTarget.GetTargetLocationForPlayer(Player, bCenter);
			FVector TargetOffset = TargetLocation - AimAtTarget.ActorLocation;

			FVector PlayerLocation = PlayerTransform.GetLocation() + (TargetOffset * DetachTimeAlpha);
			PlayerTransform.SetLocation(PlayerLocation);

			return PlayerTransform;
		}
	}

	FTransform GetCurrentPlayerTransform(EHazePlayer Player, bool bCenter) const
	{
		return GetPlayerTransformAtTime(GetLaunchTrajectory(), GetPredictedTimeSinceLaunchStart(), Player, bCenter);
	}

	void StartResetting()
	{
		State = EDentistDoubleCannonState::Resetting;
		ResetStartTime = Time::GameTimeSeconds;
	}

	void Reset()
	{
		State = EDentistDoubleCannonState::Inactive;
	}

	bool IsStateActive(EDentistDoubleCannonState InState) const
	{
		return State == InState;
	}

	void SetCannonAlpha(float Alpha)
	{
		const float RotationAlpha = Math::GetMappedRangeValueClamped(RotationAlphaRange, FVector2D(0, 1), Alpha);
		FRotator InitialRotation = FRotator(InitialPitch, InitialYaw, 0);
		FRotator TargetRotation = FRotator(TargetPitch, TargetYaw, 0);
		FRotator Rotation = Math::LerpShortestPath(InitialRotation, TargetRotation, RotationAlpha);

		YawPivotComp.SetRelativeRotation(FRotator(0, Rotation.Yaw, 0));
		PitchPivotComp.SetRelativeRotation(FRotator(Rotation.Pitch, 0, 0));

		const float LocationAlpha = Math::GetMappedRangeValueClamped(LocationAlphaRange, FVector2D(0, 1), Alpha);
		float CannonHeight = Math::Lerp(0, TargetCannonHeight, LocationAlpha);
		YawPivotComp.SetRelativeLocation(FVector(0, 0, CannonHeight));
	}

	private FVector GetLaunchLocation() const
	{
		return SpringTopComp.WorldLocation;
	}

	private void GetDetachLocationAndVelocity(FVector&out Location, FVector&out Velocity) const
	{
		FTraversalTrajectory Trajectory = GetLaunchTrajectory();
		const float DetachTime = GetDetachTime();
		Location = Trajectory.GetLocation(DetachTime);
		Velocity = Trajectory.GetVelocity(DetachTime);
	}

	private FVector GetLaunchVelocity() const
	{
		if(AimAtTarget != nullptr)
		{
			FVector Distance = AimAtTarget.ActorLocation - GetLaunchLocation();

			FVector HorizontalDistance = Distance.ConstrainToPlane(FVector::UpVector);
			float VerticalDistance = Distance.DotProduct(FVector::UpVector);

			FVector LaunchVelocity = HorizontalDistance / FlyToAimAtTargetDuration;
			LaunchVelocity += FVector::UpVector * Trajectory::GetSpeedToReachTarget(VerticalDistance, FlyToAimAtTargetDuration, -Gravity);
			return LaunchVelocity;
		}
		else
		{
			return SpringTopComp.UpVector * LaunchSpeed;
		}
	}

	private FVector GetLaunchDirection() const
	{
		return GetLaunchVelocity().GetSafeNormal();
	}

	private FTraversalTrajectory CalculateLaunchTrajectory() const
	{
#if EDITOR
		if(Editor::IsPlaying())
			check(IsStateActive(EDentistDoubleCannonState::Aiming));
#endif
		FVector InitialLocation = GetLaunchLocation();
		FVector InitialVelocity = GetLaunchVelocity();

		FTraversalTrajectory Trajectory;
		Trajectory.LaunchLocation = InitialLocation;
		Trajectory.LaunchVelocity = InitialVelocity;
		Trajectory.Gravity = FVector::DownVector * Gravity;
		
		if(AimAtTarget != nullptr)
			Trajectory.LandLocation = AimAtTarget.ActorLocation;

		return Trajectory;
	}

	FTraversalTrajectory GetLaunchTrajectory() const
	{
#if EDITOR
		if(!Editor::IsPlaying())
			return CalculateLaunchTrajectory();
#endif

		// While launching, don't allow calculating a new trajectory!
		return LaunchTrajectory;
	}

	float GetDetachTime() const
	{
		return GetLaunchTrajectory().GetTotalTime() * DetachAlpha;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Dentist::DoubleCannon::VisualizeDoubleCannon(this);
	}
#endif
};

namespace Dentist::DoubleCannon
{
#if EDITOR
	void VisualizeDoubleCannon(const ADentistDoubleCannon Cannon)
	{
		if(Cannon.AimAtTarget == nullptr)
			return;

		if(Cannon.LaunchedRoot == nullptr)
			return;

		float Time = 0;
		const float TimeStep = 1.0 / 10;

		const FTraversalTrajectory Trajectory = Cannon.GetLaunchTrajectory();

		const float Duration = Trajectory.GetTotalTime();

		float DetachTime = Duration * Cannon.DetachAlpha;

		// Simulate up until the detach
		while(Time < DetachTime)
		{
			float PreviousTime = Time;
			Time += Math::Min(TimeStep, DetachTime - Time);

			{
				// Draw the center line
				FTransform PreviousTransform = Cannon.GetLaunchedRootTransformAtTime(Trajectory, PreviousTime);
				FTransform NewTransform = Cannon.GetLaunchedRootTransformAtTime(Trajectory, Time);

				Debug::DrawDebugLine(PreviousTransform.Location, NewTransform.Location, FLinearColor::Red, 10);
			}

			{
				// Draw both player lines
				for(int i = 0; i < int(EHazePlayer::MAX); i++)
				{
					EHazePlayer Player = EHazePlayer(i);
					FTransform PreviousPlayerTransform = Cannon.GetPlayerTransformAtTime(Trajectory, PreviousTime, Player, true);
					FTransform NewPlayerTransform = Cannon.GetPlayerTransformAtTime(Trajectory, Time, Player, true);

					Debug::DrawDebugLine(PreviousPlayerTransform.Location, NewPlayerTransform.Location, GetColorForPlayer(Player), 10);
				}
			}
		}

		Time = DetachTime + KINDA_SMALL_NUMBER;
		
		// Simulate separately for each player from the detach
		for(int i = 0; i < int(EHazePlayer::MAX); i++)
		{
			float PlayerTime = Time;
			while(PlayerTime < Duration)
			{
				EHazePlayer Player = EHazePlayer(i);
				FTransform PreviousTransform = Cannon.GetPlayerTransformAtTime(Trajectory, PlayerTime, Player, true);
				PlayerTime += Math::Min(TimeStep, Duration - PlayerTime);
				FTransform NewTransform = Cannon.GetPlayerTransformAtTime(Trajectory, PlayerTime, Player, true);

				Debug::DrawDebugLine(PreviousTransform.Location, NewTransform.Location, GetColorForPlayer(Player), 10);
			}
		}

		float PointTime = (Time::GameTimeSeconds * Cannon.LaunchPlayRate) % Duration;

		const FTransform PointTransform = Cannon.GetLaunchedRootTransformAtTime(Trajectory, PointTime);
		//Debug::DrawDebugCoordinateSystem(PointTransform.Location, PointTransform.Rotator(), 300);

		if(Cannon.LaunchedRoot != nullptr && Dentist::DoubleCannon::bVisualizeWithActor)
		{
			// Mmmmmyes, using an actual actor for visualization, brilliant! 😊🔫
			Cannon.LaunchedRoot.SetActorTransform(PointTransform);
		}
		else
		{
			Debug::DrawDebugSphere(PointTransform.Location, 40, 12, FLinearColor::Blue);

			const FVector PointVelocity = Trajectory.GetVelocity(PointTime);
			Debug::DrawDebugDirectionArrow(PointTransform.Location, PointVelocity, PointVelocity.Size(), 5, FLinearColor::Blue);
		}

		for(int i = 0; i < int(EHazePlayer::MAX); i++)
		{
			EHazePlayer Player = EHazePlayer(i);

			if(Cannon.LaunchedRoot != nullptr && Dentist::DoubleCannon::bVisualizeWithActor)
			{
				FTransform PlayerTransform = Cannon.GetPlayerTransformAtTime(Trajectory, PointTime, Player, false);
				Cannon.LaunchedRoot.GetAttachmentForPlayer(Player).SetWorldTransform(PlayerTransform);
			}
			else
			{
				FTransform PlayerTransform = Cannon.GetPlayerTransformAtTime(Trajectory, PointTime, Player, true);
				Debug::DrawDebugSphere(PlayerTransform.Location, Dentist::CollisionRadius, 30, GetColorForPlayer(Player));
				//Debug::DrawDebugDirectionArrow(PlayerTransform.Location, PlayerTransform.Rotation.ForwardVector, 100, 5, GetColorForPlayer(Player));
			}
		}
	}
#endif
}