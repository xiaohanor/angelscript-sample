class ABattlefieldTransformArea : APlayerTrigger
{
	UPROPERTY(EditAnywhere)
	TPerPlayer<USkeletalMesh> Meshes;
	UPROPERTY(EditAnywhere)
	UNiagaraSystem Effect;
	
	private TPerPlayer<USkeletalMesh> OriginalMeshes;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		OnPlayerEnter.AddUFunction(this, n"OnEntered");
		OnPlayerLeave.AddUFunction(this, n"OnLeave");
	}

	UFUNCTION()
	private void OnEntered(AHazePlayerCharacter Player)
	{
		OriginalMeshes[Player] = Player.Mesh.GetSkeletalMeshAsset();
		Player.Mesh.SetSkeletalMeshAsset(Meshes[Player]);
		Niagara::SpawnOneShotNiagaraSystemAttached(Effect, Player.Mesh);
	}

	UFUNCTION()
	private void OnLeave(AHazePlayerCharacter Player)
	{
		Player.Mesh.SetSkeletalMeshAsset(OriginalMeshes[Player]);
		Niagara::SpawnOneShotNiagaraSystemAttached(Effect, Player.Mesh);
	}
}