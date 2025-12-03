struct FSkylineDroneBossScatterAttachmentLoosenedData
{
	UPROPERTY(BlueprintReadOnly)
	ASkylineDroneBossScatterAttachment Attachment;
}

struct FSkylineDroneBossScatterProjectileSpawnedData
{
	UPROPERTY(BlueprintReadOnly)
	ASkylineDroneBossScatterProjectile Projectile;
}

struct FSkylineDroneBossScatterProjectileFiredData
{
	UPROPERTY(BlueprintReadOnly)
	ASkylineDroneBossScatterProjectile Projectile;

	UPROPERTY(BlueprintReadOnly)
	FHitResult HitResult;
}

UCLASS(Abstract)
class USkylineDroneBossScatterEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotVisible, BlueprintReadOnly)
	ASkylineDroneBossScatterAttachment Attachment = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Attachment = Cast<ASkylineDroneBossScatterAttachment>(Owner);
	}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AttachmentLoosened(FSkylineDroneBossScatterAttachmentLoosenedData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ProjectileSpawned(FSkylineDroneBossScatterProjectileSpawnedData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ProjectileFired(FSkylineDroneBossScatterProjectileFiredData Data) {}

	UFUNCTION(BlueprintCallable, Meta = (AdvancedDisplay = "StartLocationName, StartTangentName, EndTangentName, EndLocationName"))
	void SetNiagaraBeamParameters(UNiagaraComponent NiagaraComponent,
		FVector StartLocation,
		FVector StartTangent,
		FVector EndTangent,
		FVector EndLocation,
		const FString& StartLocationName = "P0",
		const FString& StartTangentName = "P1",
		const FString& EndTangentName = "P2",
		const FString& EndLocationName = "P3")
	{
		if (NiagaraComponent == nullptr ||
			NiagaraComponent.IsBeingDestroyed())
			return;

		NiagaraComponent.SetNiagaraVariableVec3(StartLocationName, StartLocation);
		NiagaraComponent.SetNiagaraVariableVec3(StartTangentName, StartTangent);
		NiagaraComponent.SetNiagaraVariableVec3(EndTangentName, EndTangent);
		NiagaraComponent.SetNiagaraVariableVec3(EndLocationName, EndLocation);
	}
}