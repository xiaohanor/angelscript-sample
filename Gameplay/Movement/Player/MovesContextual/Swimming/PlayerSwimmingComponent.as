
class UPlayerSwimmingComponent : UActorComponent
{
	access AccessableFromSwimmingVolume = private, ASwimmingVolume;

	UPlayerSwimmingSettings Settings;

	UPROPERTY(BlueprintReadOnly)
	FPlayerSwimmingAnimData AnimData;

	TInstigated<EPlayerSwimmingActiveState> InstigatedSwimmingState;
	default InstigatedSwimmingState.DefaultValue = EPlayerSwimmingActiveState::Inactive;

	UPROPERTY(Category = "Dash")
	UHazeCameraSettingsDataAsset DashCameraSetting;

	UPROPERTY(Category = "Underwater")
	UHazeCameraSettingsDataAsset UnderwaterCamSettings;

	UPROPERTY(Category = "Dash")
	UForceFeedbackEffect DashFF;

	TArray<ASwimmingVolume> ActiveSwimmingVolumes;

	FPlayerSwimmingData Data;
	FPlayerSwimmingSurfaceData SurfaceData;
	FPlayerSwimmingSurfaceData PreviousSurfaceData;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UPlayerSwimmingSettings::GetSettings(Cast<AHazeActor>(Owner));
	}

	bool IsSwimming() const
	{
		return InstigatedSwimmingState.Get() == EPlayerSwimmingActiveState::Active;
	}

	UFUNCTION()
	void ApplySwimmingState(EPlayerSwimmingActiveState ActiveState, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		InstigatedSwimmingState.Apply(ActiveState, Instigator, Priority);
	}

	UFUNCTION()
	void ClearSwimmingState(FInstigator Instigator)
	{
		InstigatedSwimmingState.Clear(Instigator);
	}

	access:AccessableFromSwimmingVolume
	void SwimmingVolumeEntered(ASwimmingVolume SwimmingVolume, EPlayerSwimmingActiveState ActiveState, EInstigatePriority Priority = EInstigatePriority::Normal)
	{			
		if (ActiveState == EPlayerSwimmingActiveState::Active)
			ActiveSwimmingVolumes.AddUnique(SwimmingVolume);

		FInstigator Instigator = SwimmingVolume;	
		ApplySwimmingState(ActiveState, Instigator, Priority);
	}

	access:AccessableFromSwimmingVolume
	void SwimmingVolumeExited(ASwimmingVolume SwimmingVolume)
	{
		ActiveSwimmingVolumes.Remove(SwimmingVolume);

		FInstigator Instigator = SwimmingVolume;
		ClearSwimmingState(Instigator);
	}

	bool CheckForSurface(AHazePlayerCharacter Player, FPlayerSwimmingSurfaceData& OutSurfaceData) const
	{
		FVector WorldUp = Player.MovementWorldUp;
		for (ASwimmingVolume SwimmingVolume : ActiveSwimmingVolumes)
		{
			FVector TraceCenter = Player.ActorCenterLocation;

			FVector TraceStart = TraceCenter + WorldUp * Settings.SurfaceTraceRange;
			FVector TraceEnd = TraceCenter - WorldUp * Settings.SurfaceTraceRange;
			FVector HitLocation, HitNormal;
			FName BoneName;
			FHitResult Hit;
			SwimmingVolume.BrushComponent.LineTraceComponent(TraceStart, TraceEnd, false, false, false, HitLocation, HitNormal, BoneName, Hit);

			if (Hit.Component == nullptr)
				return false;

			const float AngleDifference = Math::RadiansToDegrees(WorldUp.AngularDistance(HitNormal));
			if (AngleDifference > 5.0)
				return false;

			// Debug::DrawDebugSphere(HitLocation, 6.0, 8, FLinearColor::Red, 2.0);
			// Debug::DrawDebugDirectionArrow(HitLocation, HitNormal, 50.0, 5.0, FLinearColor::Yellow);

			FVector ToSurface = HitLocation - TraceCenter;
			OutSurfaceData.SwimmingVolume = SwimmingVolume;
			OutSurfaceData.DistanceToSurface = ToSurface.DotProduct(WorldUp);
			OutSurfaceData.SurfaceLocation = HitLocation;
			return true;
		}
		return false;
	}

	EPlayerSwimmingState GetState() const property
	{
		return Data.State;
	}

	void SetState(EPlayerSwimmingState NewState) property
	{
		Data.State = NewState;
		AnimData.State = NewState;
	}	
}

struct FPlayerSwimmingData
{
	EPlayerSwimmingState State;
}

struct FPlayerSwimmingSurfaceData
{
	ASwimmingVolume SwimmingVolume;

	//Signed Distance to surface (Positive = above / - below)
	float DistanceToSurface = 0.0;
	
	FVector SurfaceLocation;
}

struct FPlayerSwimmingAnimData
{
	UPROPERTY()
	EPlayerSwimmingState State;

	UPROPERTY()
	float MovementScale = 0.0;

	//Are we descending/Ascending (will be represented as a value between -1 to 1)
	UPROPERTY()
	float VerticalMovementScale = 0;

	//Movement scale for CurrentSwimming in vertical and horizontal axis
	UPROPERTY()
	FVector2D CurrentSwimmingMovementScale = FVector2D::ZeroVector;

	UPROPERTY()
	FVector WantedDirection;

	UPROPERTY()
	FVector CurrentDirection;

	UPROPERTY()
	FRotator CurrentRotation;

	UPROPERTY()
	bool bDashingThisFrame = false;
}

enum EPlayerSwimmingState
{
	Inactive,
	Underwater,
	Surface,
	Dive,
	Jump,
	SurfaceDash,
	UnderwaterDash,
	ApexDive
}

enum EPlayerSwimmingActiveState
{
	Active,
	Inactive
}

class AZodiacsUglySwimmingHackActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UBillboardComponent BillboardComp;
	default BillboardComp.RelativeScale3D = FVector(3.0);

	UFUNCTION()
	void SetZodiacsUglyHackEnabled(AHazePlayerCharacter Player, bool bEnabled)
	{
		UPlayerSwimmingComponent SwimmingComp = UPlayerSwimmingComponent::Get(Player);
		// SwimmingComp.SetZodiacsUglyHackEnabled(bEnabled);
	}
}