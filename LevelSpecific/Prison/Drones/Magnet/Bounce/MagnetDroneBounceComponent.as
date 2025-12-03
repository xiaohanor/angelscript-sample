namespace MagnetDroneTags
{
	const FName BlockedWhileInMagnetDroneBounce = n"BlockedWhileInMagnetDroneBounce";
}

UCLASS(Abstract)
class UMagnetDroneBounceComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	private UMagnetDroneBounceSettings DefaultSettings;
	
	private AHazePlayerCharacter Player;
	UMagnetDroneBounceSettings Settings;

	// Bouncing
	bool bIsInBounceState = false;
	uint LastResolverBounceFrame = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		Player.ApplyDefaultSettings(DefaultSettings);

		Settings = UMagnetDroneBounceSettings::GetSettings(Player);

#if !RELEASE
		TEMPORAL_LOG(this, Owner, "MagnetDroneBounce");
#endif
	}

	bool HasResolverBouncedThisFrame() const
	{
		return LastResolverBounceFrame >= Time::FrameNumber;
	}
};