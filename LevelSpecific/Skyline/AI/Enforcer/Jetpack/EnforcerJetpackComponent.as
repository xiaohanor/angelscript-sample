event void FEnforcerJetpackRetreatStartResponseSignature();
event void FEnforcerJetpackChaseStartResponseSignature();

class UEnforcerJetpackComponent : UActorComponent
{
	private bool bUsingJetpack;
	private UEnforcerJetpackSettings JetpackSettings;

	private float JetpackCooldownDuration;
	private float JetpackCooldownTime;
	float AnimArcAlpha = 0.0;

	UPROPERTY()
	FEnforcerJetpackRetreatStartResponseSignature OnRetreatStartEvent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AHazeActor HazeActor = Cast<AHazeActor>(Owner);
		JetpackSettings = UEnforcerJetpackSettings::GetSettings(HazeActor);
		StopJetpack();
	}

	UFUNCTION(BlueprintEvent)
	void OnRetreatStart()
	{
		OnRetreatStartEvent.Broadcast();
	}

	UPROPERTY()
	FEnforcerJetpackRetreatStartResponseSignature OnChaseStartEvent;

	UFUNCTION(BlueprintEvent)
	void OnChaseStart()
	{
		OnChaseStartEvent.Broadcast();
	}

	void StartJetpack()
	{
		bUsingJetpack = true;
		AnimArcAlpha = 0.0;
	}

	void StopJetpack()
	{
		JetpackCooldownTime = Time::GetGameTimeSeconds();
		JetpackCooldownDuration = Math::RandRange(JetpackSettings.CommonCooldownMin, JetpackSettings.CommonCooldownMax);
		bUsingJetpack = false;		
	}

	bool CanUseJetpack()
	{
		return !bUsingJetpack && Time::GetGameTimeSince(JetpackCooldownTime) > JetpackCooldownDuration;
	}

	bool IsUsingJetpack() const
	{
		return bUsingJetpack;
	}
}