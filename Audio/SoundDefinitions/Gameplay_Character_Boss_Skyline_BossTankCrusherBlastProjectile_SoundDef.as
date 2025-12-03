
UCLASS(Abstract)
class UGameplay_Character_Boss_Skyline_BossTankCrusherBlastProjectile_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	ASkylineBossTankCrusherBlastProjectile CrusherBlastProjectile;

	private TArray<FAkSoundPosition> ShockwaveSoundPositions;
	default ShockwaveSoundPositions.SetNum(2);

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve ShockwaveDistanceCurve;
	default ShockwaveDistanceCurve.AddDefaultKey(0.0, 1.0);
	default ShockwaveDistanceCurve.AddDefaultKey(0.1, 1.0);
	default ShockwaveDistanceCurve.AddDefaultKey(0.25, 0.0);
	default ShockwaveDistanceCurve.AddDefaultKey(1.0, 0.0);

	UStaticMeshComponent ShockwaveMesh;
	
	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		CrusherBlastProjectile = Cast<ASkylineBossTankCrusherBlastProjectile>(HazeOwner);
		ShockwaveMesh = UStaticMeshComponent::Get(CrusherBlastProjectile, n"Plane3");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{

		for(auto Player : Game::GetPlayers())
		{
			FVector ShockwaveX1 = CrusherBlastProjectile.ActorRotation.RightVector * 2000;
			ShockwaveX1 = ShockwaveMesh.WorldLocation + ShockwaveX1;	

			FVector ShockwaveX2 = CrusherBlastProjectile.ActorRotation.RightVector * -2000;
			ShockwaveX2 = ShockwaveMesh.WorldLocation + ShockwaveX2;

			const FVector ClosestPlayerPos = Math::ClosestPointOnLine(ShockwaveX1, ShockwaveX2, Player.ActorLocation);
			ShockwaveSoundPositions[int(Player.Player)].SetPosition(ClosestPlayerPos);	
		}

		DefaultEmitter.SetMultiplePositions(ShockwaveSoundPositions);
	}	

}