enum ESandSharkLungeState
{
	None,
	Moving,
	Jumping
};

UCLASS(Abstract)
class USandSharkLungeComponent : UActorComponent
{
	ASandShark SandShark;

	ESandSharkLungeState State = ESandSharkLungeState::None;

	bool bIsLunging = false;
	bool bTargetBecameUnattackable = false;

	UPROPERTY(EditDefaultsOnly, Category="Lunge")
	UForceFeedbackEffect KillForceFeedback;
	
	UPROPERTY(EditDefaultsOnly, Category="Lunge", Meta=(ClampMin="0"))
	float ForceFeedbackMaxIntensity = 1;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SandShark = Cast<ASandShark>(Owner);
	}

	#if EDITOR
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FTemporalLog TemporalLog = TEMPORAL_LOG(SandShark);

		TemporalLog.Section("Lunge").Value(f"LungeState", State);
	}
	#endif

	FHazeTraceSettings GetTraceSettings(float Radius) const
	{
		FHazeTraceSettings Settings = Trace::InitChannel(ECollisionChannel::ECC_WorldDynamic, n"SandSharkLunge");
        Settings.UseSphereShape(Radius);
		Settings.IgnoreActor(Desert::GetLandscapeActor(SandShark.LandscapeLevel));
        Settings.IgnoreActor(SandShark);
        Settings.IgnorePlayers();
		return Settings;
	}
};