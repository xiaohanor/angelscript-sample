struct FSkylineBallBossChangedPhaseEventHandlerParams
{
	UPROPERTY()
	ESkylineBallBossPhase NewPhase;
}

enum ESkylineBallBossAttackEventHandlerType
{
	CarAppear,
	CarSmash,
	CarSlide,
	CarLob,
	CarMeteor,
	MotorcyclesAppear,
	Motorcycles,
	MotorcyclesThrowable,
	RollingBus,
	LaserStart,
	LaserStop,
}

struct FSkylineBallBossAttackEventHandlerParams
{
	UPROPERTY()
	ESkylineBallBossAttackEventHandlerType AttackType;
}

struct FSkylineBallBossUpdateDamageEventHandlerParams
{
	UPROPERTY()
	USceneComponent HatchComponent;
	UPROPERTY()
	bool bIsBeginPlay = false;
}

struct FSkylineBallBossShowPanelEventHandlerParams
{
	UPROPERTY()
	ESkylineBallBossPhase Phase;
	UPROPERTY()
	float ShowDuration;
}

class USkylineBallBossEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ChangedPhase(FSkylineBallBossChangedPhaseEventHandlerParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Attack(FSkylineBallBossAttackEventHandlerParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CarSmashCollide() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ShowPanel(FSkylineBallBossShowPanelEventHandlerParams Params) {}

	//
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHurt1Start(FSkylineBallBossUpdateDamageEventHandlerParams Params) 
	{
		DevPrintStringEvent("BallBoss", "OnHurt1Start " + Params.bIsBeginPlay, 5.0, ColorDebug::Magenta, 3.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHurt1End(FSkylineBallBossUpdateDamageEventHandlerParams Params) 
	{
		DevPrintStringEvent("BallBoss", "OnHurt1End " + Params.bIsBeginPlay, 5.0, ColorDebug::Magenta, 3.0);
	}

	//
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHurt2Start(FSkylineBallBossUpdateDamageEventHandlerParams Params) 
	{
		DevPrintStringEvent("BallBoss", "OnHurt2Start " + Params.bIsBeginPlay, 5.0, ColorDebug::Magenta, 3.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHurt2End(FSkylineBallBossUpdateDamageEventHandlerParams Params) 
	{
		DevPrintStringEvent("BallBoss", "OnHurt2End " + Params.bIsBeginPlay, 5.0, ColorDebug::Magenta, 3.0);
	}
	
	//
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHurt3Start(FSkylineBallBossUpdateDamageEventHandlerParams Params) 
	{
		DevPrintStringEvent("BallBoss", "OnHurt3Start " + Params.bIsBeginPlay, 5.0, ColorDebug::Magenta, 3.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHurt3End(FSkylineBallBossUpdateDamageEventHandlerParams Params) 
	{
		DevPrintStringEvent("BallBoss", "OnHurt3End " + Params.bIsBeginPlay, 5.0, ColorDebug::Magenta, 3.0);
	}
	
	//
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHurt4Start(FSkylineBallBossUpdateDamageEventHandlerParams Params) 
	{
		DevPrintStringEvent("BallBoss", "OnHurt4Start " + Params.bIsBeginPlay, 5.0, ColorDebug::Magenta, 3.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHurt4End(FSkylineBallBossUpdateDamageEventHandlerParams Params) 
	{
		DevPrintStringEvent("BallBoss", "OnHurt4End " + Params.bIsBeginPlay, 5.0, ColorDebug::Magenta, 3.0);
	}

	//
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHurt5Start(FSkylineBallBossUpdateDamageEventHandlerParams Params) 
	{
		DevPrintStringEvent("BallBoss", "OnHurt5Start " + Params.bIsBeginPlay, 5.0, ColorDebug::Magenta, 3.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHurt5End(FSkylineBallBossUpdateDamageEventHandlerParams Params) 
	{
		DevPrintStringEvent("BallBoss", "OnHurt5End " + Params.bIsBeginPlay, 5.0, ColorDebug::Magenta, 3.0);
	}

	//
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHurt6Start(FSkylineBallBossUpdateDamageEventHandlerParams Params) 
	{
		DevPrintStringEvent("BallBoss", "OnHurt6Start " + Params.bIsBeginPlay, 5.0, ColorDebug::Magenta, 3.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHurt6End(FSkylineBallBossUpdateDamageEventHandlerParams Params) 
	{
		DevPrintStringEvent("BallBoss", "OnHurt6End " + Params.bIsBeginPlay, 5.0, ColorDebug::Magenta, 3.0);
	}
}