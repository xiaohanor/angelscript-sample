/**
 * A component for enemies to handle moving along a spline in the GravityBike_P level.
 * The enemies move by trying to stay a certain distance away from the player.
 * If they lag behind, they speed up. If they get ahead, they slow down.
 * There is an equilibrium zone where they keep up with the players.
 * 
 * Since the enemies move on the Zoe side, but the GravityBike moves on the Mio side, the enemies will be
 * significantly delayed and look like they are lagging behind on the Mio side.
 * This is mitigated by predicting where we are supposed to be on the Mio side by extrapolating our spline distance
 * forward based on our current speed. All the enemies then move entirely locally, to ensure that they keep
 * up with the players.
 * This component can also predict the player forward if needed, but currently this is disabled.
 */
UCLASS(NotBlueprintable, HideCategories = "Activation Cooking Tags AssetUserData Navigation")
class UGravityBikeSplineEnemyMovementComponent : UActorComponent
{
#if !RELEASE
	default PrimaryComponentTick.bStartWithTickEnabled = true;
#else
	default PrimaryComponentTick.bStartWithTickEnabled = false;
#endif

	UPROPERTY(EditInstanceOnly, Category = "Movement")
	AGravityBikeSplineEnemySpline EnemySpline;

	UPROPERTY(EditAnywhere, Category = "Movement")
	float LeadAmount = 1500;

	UPROPERTY(EditAnywhere, Category = "Movement")
	float MinimumSpeed = 2000;

	UPROPERTY(EditAnywhere, Category = "Movement")
	float MaximumSpeed = 10000;

	UPROPERTY(EditAnywhere, Category = "Movement")
	float Acceleration = 10000;

	UPROPERTY(EditAnywhere, Category = "Movement")
	float Deceleration = 5000;

	UPROPERTY(EditAnywhere, Category = "Movement")
	float BackExtent = 3000;

	UPROPERTY(EditAnywhere, Category = "Movement")
	float ForwardExtent = 3000;
	
	UPROPERTY(EditAnywhere, Category = "Movement|Respawn")
	float RespawnOffset = -2000;

	private UHazeSplineComponent SplineComp;
	private float DistanceAlongSpline;
	private UHazeCrumbSyncedFloatComponent SyncedDistanceAlongSplineComp;

	float Speed;
	TInstigated<float> ForceSpeed;

	TInstigated<float> ThrottleWhenPlayerDead;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorOwnerModifiedInEditor()
	{
		if(EnemySpline == nullptr)
			return;

		SplineComp = Spline::GetGameplaySpline(EnemySpline);

		if(SplineComp == nullptr)
			return;
	
		const FTransform WorldTransform = SplineComp.GetWorldTransformAtSplineDistance(GetDistanceAlongSpline());
		Owner.SetActorLocationAndRotation(WorldTransform.Location, WorldTransform.Rotation);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(!devEnsure(EnemySpline != nullptr))
			return;

		SplineComp = Spline::GetGameplaySpline(EnemySpline);
		devCheck(SplineComp != nullptr, f"No EnemySpline assigned on {this}!");

		SyncedDistanceAlongSplineComp = UHazeCrumbSyncedFloatComponent::GetOrCreate(Owner, n"SyncedDistanceAlongSplineComp");

		SetDistanceAlongSpline(GetClosestSplineDistanceToWorldLocationExtended(Owner.ActorLocation) - RespawnOffset, true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if !RELEASE
		TEMPORAL_LOG(this).Section("Settings")
			.Value("EnemySpline", EnemySpline)
			.Value("LeadAmount", LeadAmount)
			.Value("MinimumSpeed", MinimumSpeed)
			.Value("MaximumSpeed", MaximumSpeed)
			.Value("Acceleration", Acceleration)
			.Value("Deceleration", Deceleration)
			.Value("BackExtent", BackExtent)
			.Value("ForwardExtent", ForwardExtent)
			.Value("RespawnOffset", RespawnOffset)
		;

		TEMPORAL_LOG(this).Section("Movement")
			.Transform("Current;Spline Transform", GetSplineTransform(), 500)
			.Value("Current;DistanceAlongSpline", DistanceAlongSpline)

			.Transform("Target;Transform", GetSplineTransformAtDistance(GetTargetDistanceAlongSpline()), 500)
			.Value("Target;Distance", GetTargetDistanceAlongSpline())

			.Value("Speed", Speed)
		;

		if(Network::IsGameNetworked())
		{
			float SyncedDistanceAlongSpline = SyncedDistanceAlongSplineComp.Value;
			TEMPORAL_LOG(this).Section("Network")
				.Transform("Synced;Transform", GetSplineTransformAtDistance(SyncedDistanceAlongSpline), 500)
				.Value("Synced;Distance", SyncedDistanceAlongSpline)

				.Value("IsPredictingEnemy", IsPredictingEnemy())
				.Value("IsPredictingPlayer", IsPredictingPlayer())
			;

			if(IsPredictingEnemy())
			{
				const float PredictedDistanceAlongSpline = GetPredictedEnemyDistanceAlongSpline();
				TEMPORAL_LOG(this).Section("Network").Section("Predicting Enemy")
					.Transform("Predicted;Transform", GetSplineTransformAtDistance(PredictedDistanceAlongSpline), 500)
					.Value("Predicted;Distance", PredictedDistanceAlongSpline)
				;
			}
			
			if(IsPredictingPlayer())
			{
				const FSplinePosition PlayerSplinePosition = GetSplineComp().GetClosestSplinePositionToWorldLocation(GravityBikeSpline::GetGravityBike().ActorLocation);
				const float PredictedPlayerDistanceAlongSpline = GetPredictedPlayerDistanceAlongSpline();
				const FSplinePosition PredictedPlayerSplinePosition = GetSplineComp().GetSplinePositionAtSplineDistance(PredictedPlayerDistanceAlongSpline);
				TEMPORAL_LOG(this).Section("Network").Section("Predicting Player")
					.Transform("PlayerSplinePosition;Transform", PlayerSplinePosition.WorldTransform, 500)
					.Value("PlayerSplinePosition;Distance", PlayerSplinePosition.CurrentSplineDistance)

					.Transform("PredictedSplinePosition;Transform", PredictedPlayerSplinePosition.WorldTransform, 500)
					.Value("PredictedSplinePosition;Distance", PredictedPlayerSplinePosition.CurrentSplineDistance)
				;
			}
		}
#endif
	}

	private bool IsPredictingEnemy() const
	{
		return !HasControl();
	}

	private bool IsPredictingPlayer() const
	{
		return false;

		// Currently disabled.
		// Should probably be enabled if we ever require having an enemy crumb their movement.
		//return HasControl();
	}

	void MoveSplinePositionForward(float DeltaTime)
	{
		const float Throttle = GetThrottle();
		const float TargetSpeed = GetTargetSpeed(Throttle);

		const float InterpSpeed = (TargetSpeed > Speed) ? Acceleration : Deceleration;
		Speed = Math::FInterpConstantTo(Speed, TargetSpeed, DeltaTime, InterpSpeed);

		const float Distance = DistanceAlongSpline + (Speed * DeltaTime);

		SetDistanceAlongSpline(Distance);
	}

	private float GetPredictedEnemyDistanceAlongSpline() const
	{
		check(IsPredictingEnemy());
		float SyncedDistanceAlongSpline = 0;
		float CrumbTime = 0;
		SyncedDistanceAlongSplineComp.GetLatestAvailableData(SyncedDistanceAlongSpline, CrumbTime);

		const float OtherSideCrumbTime = Time::OtherSideCrumbTrailSendTimePrediction;
		const float PredictDuration = (OtherSideCrumbTime - CrumbTime);

		return SyncedDistanceAlongSpline + (Speed * PredictDuration);
	}

	private float GetPredictedPlayerDistanceAlongSpline() const
	{
		check(IsPredictingPlayer());
		FGravityBikeSplineSyncData GravityBikeSyncData;
		float CrumbTime = 0;
		GravityBikeSpline::GetGravityBike().SyncComp.GetLatestAvailableData(GravityBikeSyncData, CrumbTime);

		const float OtherSideCrumbTime = Time::OtherSideCrumbTrailSendTimePrediction;
		const float PredictDuration = (OtherSideCrumbTime - CrumbTime);

		FSplinePosition PredictedGravityBikeSplinePosition = GravityBikeSyncData.SplinePosition;
		PredictedGravityBikeSplinePosition.Move(GravityBikeSyncData.SpeedAlongSpline * PredictDuration);

		return GetClosestSplineDistanceToWorldLocationExtended(PredictedGravityBikeSplinePosition.WorldLocation);
	}

	UFUNCTION(BlueprintPure)
	float GetThrottle() const
	{
		if(!ForceSpeed.IsDefaultValue())
		{
			return Math::GetMappedRangeValueClamped(FVector2D(MinimumSpeed, MaximumSpeed), FVector2D(0, 1), ForceSpeed.Get());
		}

		if(Game::Mio.IsPlayerDead())
			return ThrottleWhenPlayerDead.Get();

		const float TargetSplineDistance = GetTargetDistanceAlongSpline();
		const float DistanceDiff = TargetSplineDistance - GetDistanceAlongSpline();
		return Math::GetPercentageBetweenClamped(-ForwardExtent, BackExtent, DistanceDiff);
	}

	float GetTargetSpeed(float Throttle) const
	{
		if(!ForceSpeed.IsDefaultValue())
			return ForceSpeed.Get();

		return Math::Lerp(MinimumSpeed, MaximumSpeed, Throttle);
	}

	void SnapSplinePositionToClosest(FVector Location, float Offset)
	{
		const float NewSplineDistance = GetClosestSplineDistanceToWorldLocationExtended(Location);
		SetDistanceAlongSpline(NewSplineDistance + Offset);
	}

	void SnapSplinePositionToClosestToGravityBike(float Offset)
	{
		SnapSplinePositionToClosest(GravityBikeSpline::GetGravityBike().ActorLocation, Offset);
	}

	void SnapSpeed()
	{
		Speed = GetTargetSpeed(GetThrottle());
	}

	void SetDistanceAlongSpline(float InDistanceAlongSpline, bool bSetRemote = false)
	{
		if(HasControl() || bSetRemote)
			SyncedDistanceAlongSplineComp.SetValue(InDistanceAlongSpline);

		DistanceAlongSpline = Math::Max(InDistanceAlongSpline, 0);
	}

	FTransform GetSplineTransform() const
	{
		return GetSplineTransformAtDistance(DistanceAlongSpline);
	}

	FTransform GetSplineTransformAtDistance(float Distance) const
	{
		FTransform NewSplineTransform = GetSplineComp().GetWorldTransformAtSplineDistance(Distance);
		const FVector SplineUpVector = EnemySpline.GetUpAtSplineDistance(GetDistanceAlongSpline());
		const FQuat CorrectedRotation = FQuat::MakeFromXZ(NewSplineTransform.Rotation.ForwardVector, SplineUpVector);
		NewSplineTransform.SetRotation(CorrectedRotation);

		// Move forward if our distance is past the end of the spline
		if(HasPassedSplineEnd())
		{
			const float Diff = DistanceAlongSpline - GetSplineComp().SplineLength;
			NewSplineTransform.SetLocation(NewSplineTransform.Location + (NewSplineTransform.Rotation.ForwardVector * Diff));
		}

		return NewSplineTransform;
	}

	bool HasPassedSplineEnd() const
	{
		return DistanceAlongSpline >= GetSplineComp().SplineLength - KINDA_SMALL_NUMBER;
	}

	/**
	 * Get our current spline
	 */
	UHazeSplineComponent GetSplineComp() const
	{
		if(SplineComp != nullptr)
			return SplineComp;

		if(EnemySpline != nullptr)
			return Spline::GetGameplaySpline(EnemySpline);

		return nullptr;
	}

	/**
	 * Where are we currently on the spline?
	 */
	float GetDistanceAlongSpline() const
	{
		return DistanceAlongSpline;
	}

	/**
	 * Where the player is currently.
	 * Might be predicted on the Zoe side.
	 */
	float GetPlayerDistanceAlongSpline() const
	{
		if(IsPredictingPlayer())
		{
			return GetPredictedPlayerDistanceAlongSpline();
		}
		else
		{
			const FVector PlayerLocation = GravityBikeSpline::GetGravityBike().ActorLocation;
			return GetClosestSplineDistanceToWorldLocationExtended(PlayerLocation);
		}
	}

	/**
	 * Will also extend to go past the end if needed
	 */
	float GetClosestSplineDistanceToWorldLocationExtended(FVector Location) const
	{
		float Distance = SplineComp.GetClosestSplineDistanceToWorldLocation(Location);

		if(Distance > SplineComp.SplineLength - KINDA_SMALL_NUMBER)
		{
			// If the player has gone past the end of the spline, add the relative forward on it
			const FTransform EndTransform = SplineComp.GetWorldTransformAtSplineFraction(1);
			const FVector RelativeLocation = EndTransform.InverseTransformPositionNoScale(Location);

			if(RelativeLocation.X > 0)
				Distance += RelativeLocation.X;
		}

		return Distance;
	}

	/**
	 * Where we want to be along the spline
	 */
	float GetTargetDistanceAlongSpline() const
	{
		const float PlayerSplineDistance = GetPlayerDistanceAlongSpline();
		return PlayerSplineDistance + LeadAmount;
	}
};

#if EDITOR
UCLASS(NotBlueprintable)
class UGravityBikeSplineEnemyMovementComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UGravityBikeSplineEnemyMovementComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto EnemyMoveComp = Cast<UGravityBikeSplineEnemyMovementComponent>(Component.Owner);
		if(EnemyMoveComp == nullptr)
			return;

		VisualizeMovement(EnemyMoveComp);
	}

	private void VisualizeMovement(UGravityBikeSplineEnemyMovementComponent EnemyMoveComp) const
	{
		float TargetDistanceAlongSpline = 0;
		float BackDistanceAlongSpline = 0;
		float ForwardDistanceAlongSpline = 0;

		if(Editor::IsPlaying())
		{
			TargetDistanceAlongSpline = EnemyMoveComp.GetTargetDistanceAlongSpline();
			BackDistanceAlongSpline = TargetDistanceAlongSpline - EnemyMoveComp.BackExtent;
			ForwardDistanceAlongSpline = TargetDistanceAlongSpline + EnemyMoveComp.ForwardExtent;
		}
		else
		{
			TargetDistanceAlongSpline = EnemyMoveComp.GetDistanceAlongSpline() + EnemyMoveComp.LeadAmount;
			BackDistanceAlongSpline = TargetDistanceAlongSpline - EnemyMoveComp.BackExtent;
			ForwardDistanceAlongSpline = TargetDistanceAlongSpline + EnemyMoveComp.ForwardExtent;
		}

		const FTransform TargetTransform = EnemyMoveComp.GetSplineComp().GetWorldTransformAtSplineDistance(TargetDistanceAlongSpline);
		const FTransform BackTransform = EnemyMoveComp.GetSplineComp().GetWorldTransformAtSplineDistance(BackDistanceAlongSpline);
		const FTransform ForwardTransform = EnemyMoveComp.GetSplineComp().GetWorldTransformAtSplineDistance(ForwardDistanceAlongSpline);

		DrawCircle(TargetTransform.Location, 500, FLinearColor::Yellow, 30, TargetTransform.Rotation.ForwardVector);
		DrawCircle(BackTransform.Location, 500, FLinearColor::Red, 30, BackTransform.Rotation.ForwardVector);
		DrawCircle(ForwardTransform.Location, 500, FLinearColor::Green, 30, ForwardTransform.Rotation.ForwardVector);

		DrawWorldString(f"Lead Amount: {Math::RoundToInt(EnemyMoveComp.LeadAmount)}", TargetTransform.Location, FLinearColor::Yellow);
		DrawWorldString(f"Maximum Speed: {Math::RoundToInt(EnemyMoveComp.MaximumSpeed)}", BackTransform.Location, FLinearColor::Red);
		DrawWorldString(f"Minimum Speed: {Math::RoundToInt(EnemyMoveComp.MinimumSpeed)}", ForwardTransform.Location, FLinearColor::Green);
	}
}
#endif