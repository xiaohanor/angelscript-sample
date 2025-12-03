struct FMonkeySmasherForFairyLauncherAnimData
{
	access FairyLauncher = private, AMonkeySmasherForFairyLauncher;

	bool SmashedThisFrame()
	{
		if(!FrameOfSmash.IsSet())
			return false;

		return Time::FrameNumber <= FrameOfSmash.Value + 1;
	}

	access:FairyLauncher TOptional<uint> FrameOfSmash;
}

UCLASS(Abstract)
class AMonkeySmasherForFairyLauncher : AHazeActor
{
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_HazeInput;

	UPROPERTY(DefaultComponent)
	UTundraPlayerSnowMonkeyGroundSlamResponseComponent GroundSlamResponseComponent;

	FMonkeySmasherForFairyLauncherAnimData AnimData;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GroundSlamResponseComponent.OnGroundSlam.AddUFunction(this, n"OnGroundSlam");
	}

	UFUNCTION()
	private void OnGroundSlam(ETundraPlayerSnowMonkeyGroundSlamType GroundSlamType, FVector PlayerLocation)
	{
		AnimData.FrameOfSmash.Set(Time::FrameNumber);
	}
}