struct FIslandPunchotronPlayerEventData
{
	FIslandPunchotronPlayerEventData(AHazeActor _Punchotron)
	{
		Punchotron = Cast<AAIIslandPunchotron>(_Punchotron);
	}

	UPROPERTY(BlueprintReadOnly)
	AAIIslandPunchotron Punchotron;
}

struct FIslandPunchotronSidescrollerDeathPlayerEventData
{
	FIslandPunchotronSidescrollerDeathPlayerEventData(AHazeActor _Punchotron, AHazeActor _Player)
	{
		PunchotronSidescroller = Cast<AAIIslandPunchotronSidescroller>(_Punchotron);
		Player = Cast<AHazePlayerCharacter>(_Player);
#if EDITOR
		devCheck(_Punchotron != nullptr, "Couldn't cast _Punchotron param.");
		devCheck(Player != nullptr, "Couldn't cast _Player param.");
#endif
	}

	UPROPERTY(BlueprintReadOnly)
	AAIIslandPunchotronSidescroller PunchotronSidescroller;

	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter Player;
}


struct FIslandPunchotronHaywireAttackTelegraphingPlayerEventData
{
	FIslandPunchotronHaywireAttackTelegraphingPlayerEventData(AHazeActor _Punchotron, USceneComponent Location, AHazeActor InTargetActor)
	{
		Punchotron = Cast<AAIIslandPunchotron>(_Punchotron);
		VFXLocation = Location;
		TargetActor = InTargetActor;
	}

	UPROPERTY(BlueprintReadOnly)
	AAIIslandPunchotron Punchotron;

	UPROPERTY()
	USceneComponent VFXLocation;

	UPROPERTY()
	AHazeActor TargetActor;
}


UCLASS(Abstract)
class UIslandPunchotronPlayerEffectHandler : UHazeEffectEventHandler
{
   	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnPunchotronStartDying(FIslandPunchotronPlayerEventData Data) {}
    
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnPunchotronDeath(FIslandPunchotronPlayerEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnPunchotronSidescrollerDeath(FIslandPunchotronSidescrollerDeathPlayerEventData Data) {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnPunchotronStunned(FIslandPunchotronPlayerEventData Data) {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnPunchotronDamage(FIslandPunchotronPlayerEventData Data) {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnHaywireAttackTelegraphingStart(FIslandPunchotronHaywireAttackTelegraphingPlayerEventData Params) {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnHaywireAttackTelegraphingStop(FIslandPunchotronHaywireAttackTelegraphingPlayerEventData Params) {}
}

