
UCLASS(HideCategories = "Collision Debug Actor Cooking SoundDefs", Meta = (NoSourceLink))
class AHazeNiagaraActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
	UNiagaraComponent NiagaraComponent0;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;
	default DisableComp.bActorIsVisualOnly = true;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = NiagaraComponent0)
	UBillboardComponent Sprite;
	default Sprite.SetRelativeScale3D(FVector(0.5, 0.5, 0.5));
	default Sprite.bHiddenInGame = true;
	default Sprite.bIsScreenSizeScaled = true;
	default Sprite.bReceivesDecals = false;
	
	UPROPERTY(DefaultComponent, Attach = NiagaraComponent0)
	UArrowComponent ArrowComponent0;
	default ArrowComponent0.ArrowColor = FLinearColor(0.0, 1.0, 0.5);
	default ArrowComponent0.bTreatAsASprite = true;
	default ArrowComponent0.bIsScreenSizeScaled = true;
	default ArrowComponent0.bAbsoluteScale = true;
#endif

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
#if EDITOR
		Sprite.Sprite = Cast<UTexture2D>(LoadObject(nullptr, "/Niagara/Icons/S_ParticleSystem.S_ParticleSystem"));
#endif

		// For split screen purposes, we _also_ want to separately turn off rendering (but not simulation)
		// for niagara systems that are outside of disable range for one player but still
		// inside disable range for the other.
		float MaxDistance = NiagaraComponent0.GetNiagaraCullingMaxDistance();
		DisableComp.AutoDisableRange = MaxDistance;
		NiagaraComponent0.SetCullDistance(MaxDistance);
	}
};