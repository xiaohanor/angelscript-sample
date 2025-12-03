// Handles pig actor spawning and player setup
class UPlayerPigComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	USkeletalMesh MioSkelMesh;

	UPROPERTY(EditDefaultsOnly)
	USkeletalMesh ZoeSkelMesh;

	UPROPERTY(EditDefaultsOnly)
	UHazeLocomotionFeatureBundle MioFeature;

	UPROPERTY(EditAnywhere)
	UHazeLocomotionFeatureBundle ZoeFeature;

	UPROPERTY(Category = "Settings")
	UPigMovementSettings MovementSettings;

	AHazePlayerCharacter PlayerOwner;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);

		BecomePig();

		ApplyPigSettings();
	}

	// Transcend
	void BecomePig()
	{
		PlayerOwner.Mesh.SetSkeletalMeshAsset(PlayerOwner.IsMio() ? MioSkelMesh : ZoeSkelMesh);

		// Allow for pig mesh overlaps to hide actor
		PlayerOwner.Mesh.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Overlap);
		PlayerOwner.Mesh.AddTag(n"HideOnCameraOverlap");

		PlayerOwner.AddLocomotionFeatureBundle(PlayerOwner.IsMio() ? MioFeature : ZoeFeature, this, 200);

		// Override player's capsule size with pig's
		PlayerOwner.CapsuleComponent.OverrideCapsuleSize(50.0, 60.0, this);
	}

	void ApplyPigSettings()
	{
		// Movement
		PlayerOwner.ApplySettings(MovementSettings, this);
	}
}