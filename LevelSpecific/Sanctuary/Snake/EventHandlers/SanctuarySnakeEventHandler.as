struct FSanctuarySnakeEffectData
{	
	UPROPERTY()
	int Key = 0;

	UPROPERTY()
	USceneComponent Component;

	UPROPERTY()
	FTransform Transform;
}

struct FSanctuarySnakeEffectComponents
{	
	UPROPERTY()
	TArray<UNiagaraComponent> NiagaraComponents;
}

class USanctuarySnakeEventHandler : UHazeEffectEventHandler
{

	UPROPERTY(NotEditable, BlueprintReadOnly)
	ASanctuarySnake Snake;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Snake = Cast<ASanctuarySnake>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BurrowEntryStart(FSanctuarySnakeEffectData EffectData) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BurrowEntryEnd(FSanctuarySnakeEffectData EffectData) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BurrowExitStart(FSanctuarySnakeEffectData EffectData) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BurrowExitEnd(FSanctuarySnakeEffectData EffectData) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Shoot(FSanctuarySnakeEffectData EffectData) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ClearEffects() { }
}