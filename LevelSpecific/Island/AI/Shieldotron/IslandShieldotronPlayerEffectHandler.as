struct FIslandShieldotronPlayerEventData
{
	FIslandShieldotronPlayerEventData(AHazeActor _Shieldotron)
	{
		Shieldotron = Cast<AAIIslandShieldotron>(_Shieldotron);
	}

	UPROPERTY(BlueprintReadOnly)
	AAIIslandShieldotron Shieldotron;
}

struct FIslandShieldotronMortarAttackPlayerEventData
{
	FIslandShieldotronMortarAttackPlayerEventData(AHazeActor _Shieldotron , FVector _TargetLoc)
	{
		Shieldotron = Cast<AAIIslandShieldotron>(_Shieldotron);
		TargetLoc = _TargetLoc;
	}

	UPROPERTY(BlueprintReadOnly)
	AAIIslandShieldotron Shieldotron;

	UPROPERTY(BlueprintReadOnly)
	FVector TargetLoc;
}

struct FIslandShieldotronRocketAttackPlayerEventData
{
	FIslandShieldotronRocketAttackPlayerEventData(AHazeActor _Shieldotron, AHazeActor _Target)
	{
		Shieldotron = Cast<AAIIslandShieldotron>(_Shieldotron);
		Target = _Target;
	}

	UPROPERTY(BlueprintReadOnly)
	AAIIslandShieldotron Shieldotron;

	UPROPERTY(BlueprintReadOnly)
	AHazeActor Target;
}

struct FIslandShieldotronCloseRangeBlastAttackPlayerEventData
{
	FIslandShieldotronCloseRangeBlastAttackPlayerEventData(AHazeActor _Shieldotron, AHazeActor _Target)
	{
		Shieldotron = Cast<AAIIslandShieldotron>(_Shieldotron);
		Target = _Target;
	}

	UPROPERTY(BlueprintReadOnly)
	AAIIslandShieldotron Shieldotron;

	UPROPERTY(BlueprintReadOnly)
	AHazeActor Target;
}

struct FIslandShieldotronOrbAttackPlayerEventData
{
	FIslandShieldotronOrbAttackPlayerEventData(AHazeActor _Shieldotron, AHazeActor _Target)
	{
		Shieldotron = Cast<AAIIslandShieldotron>(_Shieldotron);
		Target = _Target;
	}

	UPROPERTY(BlueprintReadOnly)
	AAIIslandShieldotron Shieldotron;

	UPROPERTY(BlueprintReadOnly)
	AHazeActor Target;
}

struct FIslandShieldotronMortarTelegraphPlayerEventData
{
	FIslandShieldotronMortarTelegraphPlayerEventData(AHazeActor _Shieldotron , AHazeActor _Target)
	{
		Shieldotron = Cast<AAIIslandShieldotron>(_Shieldotron);
		Target = _Target;
	}

	UPROPERTY(BlueprintReadOnly)
	AAIIslandShieldotron Shieldotron;

	UPROPERTY(BlueprintReadOnly)
	AHazeActor Target;
}

UCLASS(Abstract)
class UIslandShieldotronPlayerEffectHandler : UHazeEffectEventHandler
{
   	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnShieldotronStartDying(FIslandShieldotronPlayerEventData Data) {}
    
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnShieldotronDeath(FIslandShieldotronPlayerEventData Data) {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnShieldotronDamage(FIslandShieldotronPlayerEventData Data) {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnShieldotronStunned(FIslandShieldotronPlayerEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartTelegraphMortarAttack(FIslandShieldotronMortarTelegraphPlayerEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunchMortarAttack(FIslandShieldotronMortarAttackPlayerEventData Data) {} 

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunchRocketAttack(FIslandShieldotronRocketAttackPlayerEventData Data) {} 
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunchCloseRangeBlastAttack(FIslandShieldotronCloseRangeBlastAttackPlayerEventData Data) {} 
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunchOrbAttack(FIslandShieldotronOrbAttackPlayerEventData Data) {} 
}

