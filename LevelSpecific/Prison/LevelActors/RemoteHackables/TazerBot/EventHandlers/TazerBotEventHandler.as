USTRUCT()
struct FTazerBotEventHandlerVFX
{
	UPROPERTY()
	UNiagaraSystem TumblingVFX;

	UPROPERTY()
	UNiagaraSystem LandingVFX;
}

USTRUCT()
struct FTazerBotOnPlayerKilledByTazerParams
{
	UPROPERTY()
	AHazePlayerCharacter TazeredPlayer = nullptr;
}

USTRUCT()
struct FTazerBotOnPlayerKnockedDownByTelescopeArmParams
{
	UPROPERTY()
	AHazePlayerCharacter KnockedPlayer = nullptr;

	UPROPERTY()
	float KnockdownDuration = 0.0;

	UPROPERTY()
	float StandUpDuration = 0.0;
}

USTRUCT()
struct FTazerBotOnPlayerKnockedDownByMovingIntoWallParams
{
	UPROPERTY()
	AHazePlayerCharacter KnockedPlayer = nullptr;

	UPROPERTY()
	float KnockdownDuration = 0.0;

	UPROPERTY()
	float StandUpDuration = 0.0;
}

class UTazerBotEventHandler : UHazeEffectEventHandler
{
	UPROPERTY()
	FTazerBotEventHandlerVFX VFX;

	ATazerBot TazerBot;

	UNiagaraComponent LandingNiagaraComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TazerBot = Cast<ATazerBot>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExtending()
	{
		
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFullyExtended()
	{
		
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRetracting()
	{
		
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTelescopeCollision(FVector Location)
	{

	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunched()
	{

	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTumblingAfterLaunch()
	{
		if (VFX.LandingVFX != nullptr)
			Niagara::SpawnOneShotNiagaraSystemAttached(VFX.TumblingVFX, TazerBot.MeshComponent, n"Head");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLandedAfterLaunch()
	{
		if (VFX.LandingVFX != nullptr)
			Niagara::SpawnOneShotNiagaraSystemAttached(VFX.LandingVFX, TazerBot.MeshComponent, n"Head");
	}

	UFUNCTION(BlueprintEvent)
	void OnImpact() {};

	UFUNCTION(BlueprintEvent)
	void OnDestroyed() {};

	UFUNCTION(BlueprintEvent)
	void OnPlayerKilledByTazer(FTazerBotOnPlayerKilledByTazerParams Params) {};

	UFUNCTION(BlueprintEvent)
	void OnKilledByMagnetPlayer() {};

	UFUNCTION(BlueprintEvent)
	void OnPlayerKnockedDownByTelescopeArm(FTazerBotOnPlayerKnockedDownByTelescopeArmParams Params) {};

	UFUNCTION(BlueprintEvent)
	void OnPlayerKnockedDownByMovingIntoWall(FTazerBotOnPlayerKnockedDownByMovingIntoWallParams Params) {};

	UFUNCTION(BlueprintPure)
	float GetExtensionFraction() const
	{
		return TazerBot.GetRodExtensionFraction();
	}

	UFUNCTION(BlueprintPure)
	ATazerBot GetTazerBot() const
	{
		return TazerBot;
	}
}