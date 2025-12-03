
struct FHazeAudioReflectionSettings
{
	const float MaximumTraceDistanceAllowed = 340 * 100.0;
	const float BaseUpwardsForwardAngle = 0;
	const float UpwardsSegments = 15;
}

class UPlayerAudioReflectionTraceCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"Audio");
	default CapabilityTags.Add(n"AudioReflection");
	default CapabilityTags.Add(Audio::Tags::DefaultReflectionTracing);
	// So we can block minor changes due to level specific additions such as additional actors on the player.
	// But we don't want to change behaviour of other feature capabilities such as Fullscreen/Static capabilities
	default CapabilityTags.Add(Audio::Tags::LevelSpecificTracingBlocking);

	default TickGroup = EHazeTickGroup::AfterGameplay;

	FHazeAudioReflectionTraceSettings TraceSettings;
	UAudioReflectionComponent ReflectionComponent;
	UHazeAudioListenerComponent Listener;
	UHazeAudioPlayerComponent PlayerComponent;
	UHazeAudioReverbComponent ReverbComponent;

	AHazeAudioZone LastZone = nullptr;
	private UHazeAudioReflectionDataAsset LastReflectionAsset;
	private const FHazeAudioReflectionSettings Settings;

	TArray<FVector> TraceDirections;
	default TraceDirections.SetNum(EHazeAudioReflectionTraceType::EHazeAudioReflectionTraceType_MAX);

	const float AngleChangePerSegment = 360.0/Settings.UpwardsSegments;
	const FVector BaseUpwardsVector = FVector::UpVector.RotateAngleAxis(Settings.BaseUpwardsForwardAngle, FVector::RightVector);
	int UpwardsCounter = 0;

	protected FVector LastForwardVector;
	private const FReflectionTraceValues EmptyTraceValues;

	FVector GetUpwardsDirection(const FVector& WorldUp, const FVector& WorldRight)
	{
		if (Settings.UpwardsSegments == 1 || Settings.BaseUpwardsForwardAngle == 0)
			return WorldUp;

		return TraceDirections[0].RotateAngleAxis(AngleChangePerSegment * UpwardsCounter, WorldUp);
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ReflectionComponent = UAudioReflectionComponent::GetOrCreate(Player);

		PlayerComponent = Player.PlayerAudioComponent;
		Listener = Player.PlayerListener;
		ReverbComponent = PlayerComponent.GetReverbComponent();

		// Will run SetupTraceDirections
		GetDirection(0);
	}

	void SetupTraceDirections(const FVector& ForwardVector, const FVector& UpVector, const FVector& RightVector)
	{
		// Start the loop from 1, we don't need to setup upwards.
		for(int i = 0; i < int(EHazeAudioReflectionTraceType::EHazeAudioReflectionTraceType_MAX); ++i)
		{
			switch(EHazeAudioReflectionTraceType(i))
			{
				case EHazeAudioReflectionTraceType::Upwards:
				TraceDirections[i] = UpVector.RotateAngleAxis(Settings.BaseUpwardsForwardAngle, RightVector);
				break;
				case EHazeAudioReflectionTraceType::NorthWest:
				TraceDirections[i] = ForwardVector.RotateAngleAxis(-45, UpVector);
				break;
				case EHazeAudioReflectionTraceType::NorthEast:
				TraceDirections[i] = ForwardVector.RotateAngleAxis(45,  UpVector);
				break;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ReflectionComponent.OnTraceDone.BindUFunction(this, n"OnTraceFinished");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ReflectionComponent.OnTraceDone.Clear();
	}

	FVector GetDirection(int DirectionIndex)
	{
		if (DirectionIndex == 0)
		{
			auto WorldUp = ReflectionComponent.WorldUp;
			// Pretend it's world right ...
			auto WorldRight = Listener.RightVector;
			auto ForwardVector = WorldRight.CrossProduct(WorldUp);

			if (ForwardVector != LastForwardVector)
			{
				LastForwardVector = ForwardVector;
				SetupTraceDirections(ForwardVector, WorldUp, WorldRight);
			}

			return GetUpwardsDirection(WorldUp, WorldRight);
		}

		return TraceDirections[DirectionIndex];
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if (ReflectionComponent.IsBusy())
			return;

		if (Game::IsInLoadingScreen())
			return;

		ReflectionComponent.InitTraceSettings(TraceSettings);
		auto Location = Listener.GetWorldLocation();

		for(int i = 0; i < 3; ++i)
		{
			FReflectionTraceValues TraceValues;
			if (LastReflectionAsset != nullptr)
				LastReflectionAsset.GetTraceValues(EHazeAudioReflectionTraceType(i), TraceValues);

			const float MaxTraceDistance = TraceValues.MaxTraceDistance == 0 ?
				Settings.MaximumTraceDistanceAllowed : TraceValues.MaxTraceDistance;

			ReflectionComponent.TraceSingle(TraceSettings, this, i, Location, Location + GetDirection(i)*MaxTraceDistance);
		}
	}

	UFUNCTION()
	void OnTraceFinished(UObject Instigator, int EnumIdentifier, const TArray<FHitResult>&in HitResults)
	{
		if (Instigator != this)
			return;

		const auto TraceType = EHazeAudioReflectionTraceType(EnumIdentifier);

		#if TEST
		if (AudioDebug::IsEnabled(EDebugAudioWorldVisualization::Delay))
		{
			for(const auto& HitResult: HitResults)
			{
				auto Color = HitResult.bBlockingHit ? FLinearColor::Green : FLinearColor::Red;
				Debug::DrawDebugLine(HitResult.TraceStart, !HitResult.bBlockingHit ? HitResult.TraceEnd : HitResult.ImpactPoint, Color);
			}
		}
		#endif

		if (TraceType == EHazeAudioReflectionTraceType::Upwards)
		{
			bool bEarlyOut = false;
			//if (!HitResults[0].bBlockingHit)
			{
				if (UpwardsCounter < Settings.UpwardsSegments)
				{
					// bEarlyOut = true;
					++UpwardsCounter;
				}
				else
					UpwardsCounter = 0;
			}
			// else
			// 	UpwardsCounter = 0;


			if (bEarlyOut)
				return;
		}

		// Start updating the zone when at least one trace has finished.
		auto CurrentZone = ReverbComponent.GetPrioritizedReverbZone();
		if (CurrentZone == nullptr)
			return;

		if (CurrentZone != LastZone || LastZone == nullptr)
		{
			LastZone = CurrentZone;
			ReflectionComponent.OnZoneChanged(CurrentZone, CurrentZone.GetReflectionAsset());
		}

		FReflectionTraceValues TraceValues = EmptyTraceValues;

		auto ReflectionAsset = CurrentZone.GetReflectionAsset();
		if (ReflectionAsset != nullptr)
		{
			ReflectionAsset.GetTraceValues(TraceType, TraceValues);
			LastReflectionAsset = ReflectionAsset;
		}

		ReflectionComponent.UpdateReflectionChannel(
			TraceType,
			TraceValues,
			HitResults[0]);
	}
}