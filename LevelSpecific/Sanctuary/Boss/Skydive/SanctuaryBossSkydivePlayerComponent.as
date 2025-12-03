class USanctuaryBossSkydivePlayerComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	UBlendSpace FallingAnimation;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem FallingVFX;

	AActor SkydiveActor;
};