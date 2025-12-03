enum EMagneticFieldChargeState
{
	None,
	Charging,
	Burst,
	Pushing
}

struct FMagneticFieldNearbyData
{
	UPROPERTY()
	int NearbyCount;

	UPROPERTY()
	float ClosestDistance = BIG_NUMBER;
}

struct FMagneticFieldLaunchData
{
	UMagneticFieldRepelComponent LaunchedFrom;
}

struct FMagneticFieldFilteredResult
{
	UMagneticFieldResponseComponent ResponseComponent;
	TArray<UPrimitiveComponent> MagneticComponents;
}

UFUNCTION(BlueprintCallable)
void AnimPrisonSetExoSuitOverrideAlpha(AHazePlayerCharacter Player, float Alpha)
{
	auto Comp = UMagneticFieldPlayerComponent::Get(Player);
	if (Comp != nullptr)
		Comp.AnimOverrideCutsceneAlpha = Alpha;
}

/**
 * Magnetic Field
 */
 UCLASS(Abstract)
class UMagneticFieldPlayerComponent : UActorComponent
{
#if EDITOR
	const bool DEBUG_DRAW = false;
#endif

	AHazePlayerCharacter Player;
	TArray<FMagneticFieldLaunchData> LaunchDatas;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset FinishedChargingCameraSettings;
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> BurstCameraShake;
	UPROPERTY()
	UCurveFloat ChargingFovCurve;

	/** Enable the shoulder override in cutscenes */
	float AnimOverrideCutsceneAlpha = 1;

	protected FOverlapResultArray NearbyOverlaps;
	protected uint NearbyOverlapsFrame = 0;

	protected EMagneticFieldChargeState ChargeState = EMagneticFieldChargeState::None;
	protected float StartChargeTime = -1;

	FMagneticFieldNearbyData CurrentNearbyData;
	uint CurrentNearbyDataFrame = 0;

	private float LastMagnetizeBurstGameTime = -1.0;

	AMagneticFieldHoverVolume CurrentHoverVolume = nullptr;

	float CurrentInnerRadius = 600.0;
	float CurrentOuterRadius = 200.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	EMagneticFieldChargeState GetChargeState() const
	{
		return ChargeState;
	}

	void SetChargeState(EMagneticFieldChargeState InState)
	{
		ChargeState = InState;

		if(ChargeState == EMagneticFieldChargeState::Charging)
		{
			StartChargeTime = Time::GameTimeSeconds;
		}
		else
		{
			StartChargeTime = -1;
		}
	}

	bool HasFinishedCharging() const
	{
		if(StartChargeTime < 0)
			return false;

		return Time::GetGameTimeSince(StartChargeTime) > GetChargeDuration();
	}

	float GetChargeDuration() const
	{
		if(CurrentHoverVolume != nullptr && CurrentHoverVolume.bSetChargeTime)
			return CurrentHoverVolume.ChargeTime;

		if(Player.IsInAir())
			return MagneticField::ChargeDurationAirborne;

		return MagneticField::ChargeDurationGrounded;
	}

	bool GetIsMagnetActive() const
	{
		return ChargeState >= EMagneticFieldChargeState::Burst;
	}

	bool HasRecentlyMagnetizeBursted(float RecentTimeWindow = 1.0) const
	{
		return Time::GetGameTimeSince(LastMagnetizeBurstGameTime) < RecentTimeWindow;
	}

	void ResetCharge()
	{
		if(!ensure(ChargeState != EMagneticFieldChargeState::None))
			return;

		UMagneticFieldEventHandler::Trigger_Stopped(Player);

		Player.ClearCameraSettingsByInstigator(this, 2.0);

		//TEMP
		Player.StopAllOverrideAnimations();

		SetChargeState(EMagneticFieldChargeState::None);

		CurrentNearbyData = FMagneticFieldNearbyData();
	}

	void UpdateRadius(float NewInner, float NewOuter)
	{
		CurrentInnerRadius = NewInner;
		CurrentOuterRadius = NewOuter;
	}

	void ResetRadius()
	{
		CurrentInnerRadius = MagneticField::InnerRadius;
		CurrentOuterRadius = MagneticField::OuterRadius;
	}

	const FOverlapResultArray& QueryNearbyOverlaps(FVector ForceOrigin)
	{
		if(NearbyOverlapsFrame < Time::FrameNumber)
		{
			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::PlayerAbilityZoe);
			Trace.UseSphereShape(MagneticField::GetTotalRadius());
			Trace.IgnorePlayers();

#if EDITOR
			if(DEBUG_DRAW)
				Trace.DebugDrawOneFrame();
#endif

			NearbyOverlaps = Trace.QueryOverlaps(ForceOrigin);

#if EDITOR
			FTemporalLog TemporalLog = TEMPORAL_LOG(this);
			TemporalLog.OverlapResults("TraceForNearbyOverlaps", NearbyOverlaps);
#endif

			NearbyOverlapsFrame = Time::FrameNumber;
		}

		return NearbyOverlaps;
	}

	TMap<AActor, FMagneticFieldFilteredResult> FilterNearbyOverlapsForMagnetize(const FOverlapResultArray& Overlaps) const
	{
		TMap<AActor, FMagneticFieldFilteredResult> FilteredOverlaps;

		for(auto Overlap : Overlaps)
		{
			if (Overlap.Actor == nullptr || Overlap.Component == nullptr)
				continue;

			FMagneticFieldFilteredResult FilteredResult;
			if(FilteredOverlaps.Find(Overlap.Actor, FilteredResult))
			{
				FilteredResult.MagneticComponents.Add(Overlap.Component);
				FilteredOverlaps[Overlap.Actor] = FilteredResult;
			}
			else
			{
				FilteredResult.ResponseComponent = UMagneticFieldResponseComponent::Get(Overlap.Actor);
				FilteredResult.MagneticComponents.Add(Overlap.Component);
				FilteredOverlaps.Add(Overlap.Actor, FilteredResult);
			}
		}

		return FilteredOverlaps;
	}

	bool IsInMagneticZone()
	{
		const FVector PlayerLocation = Player.GetActorCenterLocation();

		const FVector ForceOrigin = GetMagneticFieldCenterPoint();
		for (const auto& Overlap : QueryNearbyOverlaps(ForceOrigin))
		{
			auto MagneticField = UMagneticFieldRepelComponent::Get(Overlap.Actor);
			if(MagneticField == nullptr)
				continue;

			if(IsLaunchedBy(MagneticField))
				continue;
			
			float VerticalDist;
			if (MagneticField.IsPointInsideZone(PlayerLocation, false, VerticalDist))
				return true;
		}

		return false;
	}

	FVector GetMagneticFieldCenterPoint() const
	{
		return Player.ActorLocation + (Player.MovementWorldUp * 100.0);
	}

	void BurstMagnetizeNearbyActors(FVector ForceOrigin, const TMap<AActor,FMagneticFieldFilteredResult> FilteredResults)
	{
		MagnetizeNearbyActors(ForceOrigin, FilteredResults, true);

		// Record when the last time was the player used their magnet burst
		LastMagnetizeBurstGameTime = Time::GameTimeSeconds;
	}

	void PushMagnetizeNearbyActors()
	{
		// Get all magnetic components within a radius
		const FVector ForceOrigin = GetMagneticFieldCenterPoint();
		const FOverlapResultArray Results = QueryNearbyOverlaps(ForceOrigin);

		/*
		 * Filter them to an Actor -> Components TMap
		 * Reduces the risk of running the same code for the same actor multiple times,
		 * while also not getting components on the same actor for each component
		 */
		const TMap<AActor,FMagneticFieldFilteredResult> FilteredResults = FilterNearbyOverlapsForMagnetize(Results);

		MagnetizeNearbyActors(ForceOrigin, FilteredResults, false);
	}

	void MagnetizeNearbyActors(FVector ForceOrigin, const TMap<AActor,FMagneticFieldFilteredResult> FilteredResults, bool bBurst)
	{
		CurrentNearbyData = FMagneticFieldNearbyData();
		CurrentNearbyDataFrame = Time::FrameNumber;

		// Store a map of what response components have been hit, and data relevant to those
		TMap<UMagneticFieldResponseComponent, FMagneticFieldData> MagneticFieldResponseDatas;

		for (auto Result : FilteredResults)
		{
			// Check if the actor is valid
			if(!IsValid(Result.Key))
				continue;

			// Check if the actor is magnetized
			if(IsValid(Result.Value.ResponseComponent))
			{
				if(!Result.Value.ResponseComponent.bMagnetized)
					continue;
			}

			for(auto Component : Result.Value.MagneticComponents)
			{
				if(!IsValid(Component))
					continue;

				// We want to push the closest point on the overlapped component
				FVector ForceAffectPoint;
				const float Distance = Component.GetClosestPointOnCollision(ForceOrigin, ForceAffectPoint);
				if(Distance < -KINDA_SMALL_NUMBER)
				{
					// GetClosestPointOnCollision returned invalid
					continue;
				}
				else if(Distance < KINDA_SMALL_NUMBER)
				{
					// Distance is ~0, we are probably inside of the collider
					// Move the affect points slightly towards the component location, which might fix it
					ForceAffectPoint += (Component.WorldLocation - ForceAffectPoint).GetSafeNormal();
				}

				// Store that we found a nearby component, and keep track of the distance to the closest one
				CurrentNearbyData.NearbyCount++;

				if(Distance < CurrentNearbyData.ClosestDistance)
					CurrentNearbyData.ClosestDistance = Distance;

				// The following code only works if we have a response component
				if(Result.Value.ResponseComponent == nullptr)
					continue;

				// Find the current response component in the map, or add it
				FMagneticFieldData ResponseData;
				bool bDataExists = false;
				if(MagneticFieldResponseDatas.Find(Result.Value.ResponseComponent, ResponseData))
				{
					bDataExists = true;
				}
				else
				{
					// Initialize data which is the same for all components affected through this response component
					ResponseData.bBurst = bBurst;
					ResponseData.ForceOrigin = ForceOrigin;
				}

				AddToResponseData(ResponseData, Component, ForceAffectPoint, Distance);

				// Update (or add) the response component data
				if(bDataExists)
					MagneticFieldResponseDatas[Result.Value.ResponseComponent] = ResponseData;
				else
					MagneticFieldResponseDatas.Add(Result.Value.ResponseComponent, ResponseData);
			}
		}

		for(auto ResponseData : MagneticFieldResponseDatas)
		{
			// For each response component, call Burst/Push
			if (ResponseData.Value.bBurst)
			{
				ResponseData.Key.BurstActivated(ResponseData.Value);
			}
			else
			{
				ResponseData.Key.UpdatePush(ResponseData.Value);
			}
		}

		// If we affected anything, trigger an event on the player
		if(MagneticFieldResponseDatas.Num() > 0)
		{
			// We use a different array since we want to include the response component, and combine all into one struct
			FMagneticFieldPushEventData PushEventData;
			for(auto PushData : MagneticFieldResponseDatas)
			{
				FMagneticFieldPushEventDataEntry Entry;
				Entry.ResponseComp = PushData.Key;
				Entry.PushData = PushData.Value;
				PushEventData.Data.Add(Entry);

#if EDITOR
				if(DEBUG_DRAW)
				{
					for(auto ComponentData : Entry.PushData.ComponentDatas)
						Debug::DrawDebugLine(ForceOrigin, ComponentData.ForceAffectPoint, FLinearColor::Green);
				}
#endif
			}

			if(bBurst)
				UMagneticFieldEventHandler::Trigger_MagneticBurst(Player, PushEventData);
			else
				UMagneticFieldEventHandler::Trigger_MagneticPush(Player, PushEventData);
		}
	}

	private void AddToResponseData(FMagneticFieldData& ResponseData, USceneComponent Component, FVector ForceAffectPoint, float Distance) const
	{
		FMagneticFieldComponentData ComponentData;
		ComponentData.AffectedComp = Component;
		ComponentData.ForceAffectPoint = ForceAffectPoint;

		// Calculate the proximity to the magnetic component point
		// Initialize to 1 so that any component within the inner radius has a proximity of 1
		float ProximityFraction = 1.0;

		if (Distance > CurrentInnerRadius)
		{
			const float DistFromInnerRadius = (Distance - CurrentInnerRadius);
			ProximityFraction = Math::Clamp(DistFromInnerRadius / CurrentOuterRadius, 0.0, 1.0);
			ProximityFraction = 1.0 - ProximityFraction;	// Inverse since this will be used to multiply forces, so we want it to decrease with distance
		}

		ComponentData.ProximityFraction = ProximityFraction;

		// Add the component data to the current response component data
		ResponseData.ComponentDatas.Add(ComponentData);
	}

	UFUNCTION(BlueprintPure)
	bool GetIsAffectingAnything() const
	{
		if(CurrentNearbyDataFrame < Time::FrameNumber)
			return false;

		return CurrentNearbyData.NearbyCount > 0;
	}

	// Returns -1 if we did not magnetically affect anything this frame
	UFUNCTION(BlueprintCallable)
	float GetDistanceToClosestAffected() const
	{
		if(CurrentNearbyDataFrame < Time::FrameNumber)
			return -1;

		if(CurrentNearbyData.NearbyCount == 0)
			return -1;

		return CurrentNearbyData.ClosestDistance;
	}

	UFUNCTION(BlueprintPure)
	FMagneticFieldNearbyData GetNearbyData() const
	{
		return CurrentNearbyData;
	}

	UFUNCTION(BlueprintPure)
	bool IsLaunched() const
	{
		return LaunchDatas.Num() > 0;
	}

	UFUNCTION(BlueprintPure)
	bool IsLaunchedBy(UMagneticFieldRepelComponent MagneticField) const
	{
		for(auto& LaunchData : LaunchDatas)
		{
			if(LaunchData.LaunchedFrom == MagneticField)
				return true;
		}

		return false;
	}
}