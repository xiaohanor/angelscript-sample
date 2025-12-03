UCLASS(Abstract)
class UPirateShipPlayerComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<APirateEyePatch> MioEyePatchClass;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<APirateEyePatch> ZoeEyePatchClass;

	// UPROPERTY(EditDefaultsOnly)
	// TSubclassOf<APirateShark> SharkClass;

	// UPROPERTY(EditDefaultsOnly)
	// UHazeCameraSpringArmSettingsDataAsset SharkDeathCameraSettings;

	private AHazePlayerCharacter Player;
	// bool bGetEatenByShark = false;

	// TSet<APirateSharkSafeVolume> SharkSafeVolumes;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		// auto ResponseComp = UPirateShipCannonBallResponseComponent::GetOrCreate(Owner);

		// ResponseComp.OnDirectHit.AddUFunction(this, n"OnDirectHit");
		// ResponseComp.OnExplosionHit.AddUFunction(this, n"OnExplosionHit");

		TSubclassOf<APirateEyePatch> EyePatchClass = Player.IsMio() ? MioEyePatchClass : ZoeEyePatchClass;
		if(EyePatchClass != nullptr)
		{
			auto EyePatch = SpawnActor(EyePatchClass);
			//EyePatch.AttachToComponent(Player.Mesh, n"Head", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
			Outline::ApplyNoOutlineOnActor(EyePatch, Player.OtherPlayer, this, EInstigatePriority::High);
		}
	}

	// UFUNCTION()
	// private void OnDirectHit(FPirateShipCannonBallOnDirectHitParams Params)
	// {
	// 	Player.KillPlayer();
	// }

	// UFUNCTION()
	// private void OnExplosionHit(FPirateShipCannonBallOnExplosionHitParams Params)
	// {
	// 	float Range = Params.CannonBall.ExplosionRadius;
	// 	const float DistanceToExplosion = Player.ActorCenterLocation.Distance(Params.ExplosionLocation);
	// 	const float ExplosionAlpha = 1.0 - Math::Saturate(Math::NormalizeToRange(DistanceToExplosion, 0, Range));

	// 	Player.DamagePlayerHealth(ExplosionAlpha);
	// }

	// bool IsInSharkSafeVolume() const
	// {
	// 	return !SharkSafeVolumes.IsEmpty();
	// }
};