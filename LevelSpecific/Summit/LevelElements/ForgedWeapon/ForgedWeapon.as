class AForgedWeapon : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UBillboardComponent ProjectileSpawnLocation;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent AcidCanon;
	default AcidCanon.UsableByPlayers = EHazeSelectPlayer::Mio;
	default AcidCanon.InteractionCapability = n"ForgedWeaponCanonCapability";

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCameraComponent Camera;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AForgedWeaponProjectile> Projectile;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AcidCanon.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		AcidCanon.OnInteractionStopped.AddUFunction(this, n"OnInteractionStopped");

	}

	UFUNCTION()
	private void OnInteractionStopped(UInteractionComponent Interaction, AHazePlayerCharacter Player)
	{
		Player.DeactivateCamera(Camera, 2.0);
	}


	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent Interaction, AHazePlayerCharacter Player)
	{

		Player.ActivateCamera(Camera, 2.0, this);
	}


	


}