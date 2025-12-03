class UControllableDropShipDrawComponent : UHazeEditorRenderedComponent
{
	default bIsEditorOnly = true;
	default SetHiddenInGame(true);

	UFUNCTION(BlueprintOverride)
	void CreateEditorRenderState()
	{
#if EDITOR
		AControllableDropShip DropShip = Cast<AControllableDropShip>(Owner);
		if (DropShip == nullptr)
			return;

		SetActorHitProxy();

		for (int i = 0; i < DropShip.EnemyShipSpawnVerticalOffsets.Num(); i++)
		{
			FVector SpawnLoc = DropShip.ActorLocation;
			FVector SpawnDir = -DropShip.ActorForwardVector.RotateAngleAxis(DropShip.EnemyShipSpawnAngleOffsets[i], FVector::UpVector);
			SpawnLoc += SpawnDir * ControllableDropShip::EnemyDistance;
			SpawnLoc += FVector::UpVector * DropShip.EnemyShipSpawnVerticalOffsets[i];
			DrawWireBox(SpawnLoc, FVector(900.0, 700.0, 300.0), SpawnDir.Rotation().Quaternion(), FLinearColor::Green, 25.0);

			FVector DodgeLoc = DropShip.ActorLocation;
			FVector DodgeDir = -DropShip.ActorForwardVector.RotateAngleAxis(DropShip.EnemyShipDodgeAngleOffsets[i], FVector::UpVector);
			DodgeLoc += DodgeDir * ControllableDropShip::EnemyDistance;
			DodgeLoc += FVector::UpVector * DropShip.EnemyShipDodgeVerticalOffsets[i];
			DrawWireBox(DodgeLoc, FVector(900.0, 700.0, 300.0), DodgeDir.Rotation().Quaternion(), FLinearColor::Red, 25.0);

			DrawArrow(SpawnLoc, DodgeLoc, FLinearColor::Purple, 200.0, 20.0);
		}
		
		ClearHitProxy();
		
#endif
	}
}