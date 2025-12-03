class UGoatTeleportPlayerComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<AGoatTeleportPreviewActor> PreviewClass;
	AGoatTeleportPreviewActor PreviewActor;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset TargetCamSettings;

	UPROPERTY()
	UCurveFloat ScaleCurve;

	UPROPERTY()
	UNiagaraSystem DisapperEffect;

	UPROPERTY()
	UNiagaraSystem AppearEffect;

	UPROPERTY()
	UNiagaraSystem TeleportTrail;

	bool bValidTarget = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PreviewActor = SpawnActor(PreviewClass);
		PreviewActor.SetActorHiddenInGame(true);
	}
}