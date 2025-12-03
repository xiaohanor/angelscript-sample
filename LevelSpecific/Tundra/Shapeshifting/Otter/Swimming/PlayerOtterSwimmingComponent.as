
class UTundraPlayerOtterSwimmingComponent : UActorComponent
{
	access AccessableFromSwimmingVolume = private, ASwimmingVolume (inherited);

	UTundraPlayerOtterSwimmingSettings Settings;

	UPROPERTY(BlueprintReadOnly)
	FTundraPlayerOtterSwimmingAnimData AnimData;

	TInstigated<ETundraPlayerOtterSwimmingActiveState> InstigatedSwimmingActiveState;
	default InstigatedSwimmingActiveState.DefaultValue = ETundraPlayerOtterSwimmingActiveState::Inactive;

	UPROPERTY()
	UHazeCameraSettingsDataAsset DashCameraSetting;

	UPROPERTY()
	UHazeCameraSettingsDataAsset SwimmingCamSettings;

	UPROPERTY()
	UHazeCameraSettingsDataAsset UnderwaterCamSettings;

	TArray<ASwimmingVolume> ActiveSwimmingVolumes;

	FTundraPlayerOtterSwimmingSurfaceData SurfaceData;
	FTundraPlayerOtterSwimmingSurfaceData PreviousSurfaceData;
	private ETundraPlayerOtterSwimmingState Internal_CurrentState = ETundraPlayerOtterSwimmingState::Inactive;
	private ETundraPlayerOtterSwimmingState Internal_PreviousState = ETundraPlayerOtterSwimmingState::Inactive;
	private uint Internal_FrameOfChangeState;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UTundraPlayerOtterSwimmingSettings::GetSettings(Cast<AHazeActor>(Owner));
	}

	bool IsSwimming() const
	{
		return InstigatedSwimmingActiveState.Get() == ETundraPlayerOtterSwimmingActiveState::Active;
	}

	void SetCurrentState(ETundraPlayerOtterSwimmingState State) property
	{
		Internal_PreviousState = Internal_CurrentState;
		Internal_CurrentState = State;
		AnimData.State = State;
		Internal_FrameOfChangeState = Time::FrameNumber;
	}

	ETundraPlayerOtterSwimmingState GetCurrentState() const property
	{
		return Internal_CurrentState;
	}

	ETundraPlayerOtterSwimmingState GetPreviousState() const property
	{
		return Internal_PreviousState;
	}

	uint GetFrameOfChangeState() const property
	{
		return Internal_FrameOfChangeState;
	}

	bool ChangedStateThisFrameOrLast() const
	{
		return Internal_FrameOfChangeState >= Time::FrameNumber - 1;
	}

	UFUNCTION()
	void ApplySwimmingState(ETundraPlayerOtterSwimmingActiveState State, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		InstigatedSwimmingActiveState.Apply(State, Instigator, Priority);
	}

	UFUNCTION()
	void ClearSwimmingState(FInstigator Instigator)
	{
		InstigatedSwimmingActiveState.Clear(Instigator);
	}

	access:AccessableFromSwimmingVolume
	void SwimmingVolumeEntered(ASwimmingVolume SwimmingVolume, ETundraPlayerOtterSwimmingActiveState State, EInstigatePriority Priority = EInstigatePriority::Normal)
	{			
		if (State == ETundraPlayerOtterSwimmingActiveState::Active)
			ActiveSwimmingVolumes.AddUnique(SwimmingVolume);

		FInstigator Instigator = SwimmingVolume;	
		ApplySwimmingState(State, Instigator, Priority);
	}

	access:AccessableFromSwimmingVolume
	void SwimmingVolumeExited(ASwimmingVolume SwimmingVolume)
	{
		ActiveSwimmingVolumes.Remove(SwimmingVolume);

		FInstigator Instigator = SwimmingVolume;
		ClearSwimmingState(Instigator);
	}

	bool CheckForSurface(AHazePlayerCharacter Player, FTundraPlayerOtterSwimmingSurfaceData& OutSurfaceData) const
	{
		return CheckForSurface(Player.ActorCenterLocation, Player.MovementWorldUp, OutSurfaceData);
	}

	bool CheckForSurface(FVector Location, FVector WorldUp, FTundraPlayerOtterSwimmingSurfaceData& OutSurfaceData) const
	{
		for (ASwimmingVolume SwimmingVolume : ActiveSwimmingVolumes)
		{
			FVector TraceCenter = Location;

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

			FVector ToSurface = HitLocation - TraceCenter;
			OutSurfaceData.SwimmingVolume = SwimmingVolume;
			OutSurfaceData.DistanceToSurface = ToSurface.DotProduct(WorldUp);
			OutSurfaceData.SurfaceLocation = HitLocation;
			return true;
		}
		return false;
	}
}

struct FTundraPlayerOtterSwimmingSurfaceData
{
	ASwimmingVolume SwimmingVolume;

	//Signed Distance to surface (Positive = above / - below)
	float DistanceToSurface = 0.0;
	FVector SurfaceLocation;
}

struct FTundraPlayerOtterSwimmingAnimData
{
	UPROPERTY()
	ETundraPlayerOtterSwimmingState State;

	UPROPERTY()
	float MovementScale = 0.0;

	//Are we descending/Ascending (will be represented as a value between -1 to 1)
	UPROPERTY()
	float VerticalMovementScale = 0;

	UPROPERTY()
	FVector WantedDirection;

	UPROPERTY()
	FVector CurrentDirection;

	UPROPERTY()
	FRotator CurrentRotation;

	UPROPERTY()
	bool bDashingThisFrame = false;

	UPROPERTY()
	bool bSonarBlasting = false;
}

enum ETundraPlayerOtterSwimmingState
{
	Inactive,
	Underwater,
	Surface,
	Dive,
	Jump,
	SurfaceDash,
	UnderwaterDash
}

enum ETundraPlayerOtterSwimmingActiveState
{
	Active,
	Inactive
}