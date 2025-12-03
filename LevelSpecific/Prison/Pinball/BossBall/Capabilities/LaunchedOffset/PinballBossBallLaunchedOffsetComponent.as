#if !RELEASE
namespace DevTogglesPinball
{
	const FHazeDevToggleBool DisableBossBallLaunchedOffset;
};
#endif

struct FPinballBossBallLaunchedOffset
{
	FVector VisualLocation;
	FVector OffsetPlane;
	float ReturnOffsetDuration;
	float StartOffsetTime;
};

// I hate the MeshOffsetComponent lerp, so this is basically that but it doesn't just fully stop when activated
UCLASS(NotBlueprintable)
class UPinballBossBallLaunchedOffsetComponent : UActorComponent
{
	default TickGroup = ETickingGroup::TG_LastDemotable;

	private APinballBossBall BossBall;

	TOptional<FPinballBossBallLaunchedOffset> LaunchedOffsetToConsume;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BossBall = Cast<APinballBossBall>(Owner);

#if !RELEASE
		DevTogglesPinball::DisableBossBallLaunchedOffset.MakeVisible();
#endif
	}

	void ApplyLaunchedOffset(
		FPinballLauncherLerpBackSettings LerpBackSettings,
		FVector LaunchLocation,
		FVector LaunchImpulse,
		FVector VisualLocation
	)
	{
		check(LerpBackSettings.bLerpBack);

		FPinballBossBallLaunchedOffset LaunchedOffset;
		LaunchedOffset.VisualLocation = VisualLocation;
		LaunchedOffset.ReturnOffsetDuration = LerpBackSettings.GetLerpBackDuration();
		if(LaunchedOffset.ReturnOffsetDuration < KINDA_SMALL_NUMBER)
			return;

		if(LerpBackSettings.bOnlyLerpBackHorizontally)
		{
			LaunchedOffset.OffsetPlane = LaunchImpulse.GetSafeNormal2D(FVector::ForwardVector);
		}
		else
		{
			LaunchedOffset.OffsetPlane = FVector::ZeroVector;
		}

		LaunchedOffset.StartOffsetTime = Time::GameTimeSeconds;

		LaunchedOffsetToConsume.Set(LaunchedOffset);
	}

	bool HasOffsetToConsume() const
	{
		return LaunchedOffsetToConsume.IsSet();
	}

	FPinballBossBallLaunchedOffset ConsumeOffset()
	{
		FPinballBossBallLaunchedOffset Offset = LaunchedOffsetToConsume.Value;
		LaunchedOffsetToConsume.Reset();
		return Offset;
	}
};