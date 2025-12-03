
UCLASS(Abstract)
class AWaveRaftTsunami : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere, Category = "Wave Raft Tsunami")
	AWaveRaft WaveRaft;

	UPROPERTY(DefaultComponent)
	UHazeOffsetComponent OffsetComp;

	default PrimaryActorTick.TickGroup = ETickingGroup::TG_PostPhysics;

	private bool bEnabled = false;

	FHazeAcceleratedRotator AccRotation;
	FHazeAcceleratedVector AccLocation;
	FHazeAcceleratedFloat AccHeight;

	float TimeActivated;
	FSplinePosition WaveSplinePosition;

	float ForwardVelocity;

	UPROPERTY(EditAnywhere)
	bool bIsUsedForSequence = true;

	const float WaveSplineOffsetToRaft = -250 * 1;
	float LocationAccelerationDuration = 0.5;
	float RotationAccelerationDuration = 0.5;
	float HeightAccelerationDuration = 1.5;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorCollisionBlock(this);
		if (!bIsUsedForSequence)
			SetActorHiddenInGame(true);

		bEnabled = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (HasControl())
		{
			// Enable the tsunami if the raft is enabled
			if (WaveRaft == nullptr || WaveRaft.IsActorDisabled() || !WaveRaft.bRaftIsOnWave)
			{
				if (bEnabled)
					CrumbDisableMovement();
			}
			else
			{
				if (!bEnabled)
					CrumbEnableMovement();
			}
		}

		// Move the tsunami after the raft moves
		if (bEnabled)
		{
			if (!Game::Mio.IsPlayerDeadOrRespawning())
			{
				WaveSplinePosition = WaveRaft.SplinePos;
				WaveSplinePosition.Move(WaveSplineOffsetToRaft);
			}
			else
			{
				WaveSplinePosition.Move(5000 * DeltaSeconds);
			}

			FRotator WaveRotation = WaveSplinePosition.WorldRotation.Rotator();
			FVector WaveLocation = WaveSplinePosition.WorldLocation;
			OffsetWaveLocation(WaveSplinePosition, WaveLocation);

			float Delta = DeltaSeconds;
			if (Delta == 0)
				Delta = 0.016;

			ForwardVelocity = (WaveLocation - ActorLocation).DotProduct(WaveSplinePosition.WorldForwardVector) / Delta;
			AccLocation.AccelerateTo(WaveLocation, LocationAccelerationDuration, DeltaSeconds);
			AccRotation.AccelerateTo(WaveRotation, RotationAccelerationDuration, DeltaSeconds);

			AccHeight.AccelerateTo(WaveLocation.Z, HeightAccelerationDuration, DeltaSeconds);
			FVector DesiredLocation = AccLocation.Value;
			DesiredLocation.Z = AccHeight.Value;

			SetActorLocationAndRotation(DesiredLocation, AccRotation.Value);
			BP_UpdateWaveSize(WaveSplinePosition.WorldScale3D.Y * 30.0, WaveSplinePosition.WorldScale3D.Z * 30.0);
		}
	}

	void OffsetWaveLocation(FSplinePosition SplinePos, FVector& WaveLocation)
	{
		WaveLocation.Z = SplinePos.WorldLocation.Z - 250 * 1.25;
	}

	UFUNCTION(BlueprintEvent)
	void BP_UpdateWaveSize(float WaveWidth, float WaveHeight) {}

	UFUNCTION(CrumbFunction)
	void CrumbEnableMovement()
	{
		SetActorHiddenInGame(false);
		bEnabled = true;
		TimeActivated = Time::GameTimeSeconds;

		WaveSplinePosition = WaveRaft.SplinePos;
		AccLocation.SnapTo(ActorLocation);
		AccRotation.SnapTo(ActorRotation);
		AccHeight.SnapTo(ActorLocation.Z);
		BP_UpdateWaveSize(WaveSplinePosition.WorldScale3D.Y * 30.0, WaveSplinePosition.WorldScale3D.Z * 30.0);
	}

	UFUNCTION(CrumbFunction)
	void CrumbDisableMovement()
	{
		bEnabled = false;
	}
};