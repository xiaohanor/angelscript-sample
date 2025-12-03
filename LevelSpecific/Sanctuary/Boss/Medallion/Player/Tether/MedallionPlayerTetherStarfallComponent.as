UCLASS(Abstract)
class UMedallionPlayerTetherStarfallTrailComponent : UNiagaraComponent
{
	default SetAutoActivate(false);

	UPROPERTY(EditAnywhere)
	FMegaCompanionEvent MegaCompanionStartDisintegrating;
	UPROPERTY(EditAnywhere)
	FMegaCompanionEvent MegaCompanionFinishedDisintegrating;
}