struct FPigWorldSausageParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

struct FPigWorldSausageRollParams
{
	UPROPERTY()
	float RollSpeedAlpha;
}


UCLASS(Abstract)
class UPigSausageEventHandler : UHazeEffectEventHandler
{
    UPROPERTY()
	UNiagaraSystem Smoke;

    UPROPERTY()
	UNiagaraSystem Fire;

	UPROPERTY()
	UNiagaraSystem Explosion;

	UPROPERTY(EditAnywhere)
	UDeathEffect DeathEffect;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Event(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGrillEvent(FPigWorldSausageParams Params){}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OffGrillEvent(FPigWorldSausageParams Params){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HotDogReadyEvent(FPigWorldSausageParams Params){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartSmokeEvent(FPigWorldSausageParams Params){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopSmokeEvent(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartFireEvent(FPigWorldSausageParams Params){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopFireEvent(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ExplosionEvent(FPigWorldSausageParams Params){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void JumpEvent(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LandEvent(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FlopEvent(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RollingEvent(FPigWorldSausageRollParams Params){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartRollingEvent(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopRollingEvent(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SausageIsGrilledWithCondiments(FPigWorldSausageParams Params){}

};