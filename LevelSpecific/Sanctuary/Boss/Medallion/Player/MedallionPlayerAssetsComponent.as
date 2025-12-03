UCLASS(Abstract)
class UMedallionPlayerAssetsComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem StartFlyingVFX;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem MioTetherVFX;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem ZoeTetherVFX;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect CutHeadFFEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CutHeadCS;

	UPROPERTY(EditDefaultsOnly)
	UPlayerHealthSettings MergePhaseHealthSettings;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AMedallionMedallionActor> MedallionClassMio;
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AMedallionMedallionActor> MedallionClassZoe;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect KnockedByHydraEffect;

	UPROPERTY(EditDefaultsOnly)
	TPerPlayer<UHazeLocomotionFeatureBase> MedallionLocomotionFeature;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UMedallionPlayerTetherComponent> TetherVFXCompClass;
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UMedallionPlayerTetherStarfallTrailComponent> TrailStarfallVFXCompClass;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
		if (Player.IsMio() && MedallionClassMio != nullptr)
		{
			AMedallionMedallionActor MedallionActor = SpawnActor(MedallionClassMio, Owner.ActorLocation, Owner.ActorRotation, MedallionStatics::SanctuaryGetMedallionName(Player), true);
			MedallionActor.MakeNetworked(Player, n"Medallion");
			FinishSpawningActor(MedallionActor);
		}
		if (Player.IsZoe() && MedallionClassZoe != nullptr)
		{
			AMedallionMedallionActor MedallionActor = SpawnActor(MedallionClassZoe, Owner.ActorLocation, Owner.ActorRotation, MedallionStatics::SanctuaryGetMedallionName(Player), true);
			MedallionActor.MakeNetworked(Player, n"Medallion");
			FinishSpawningActor(MedallionActor);
		}
	}
};