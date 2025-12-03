UCLASS(Abstract)
class ASchmellTowerManager : AHazeActor
{
	UPROPERTY(EditInstanceOnly)
	TArray<ASchmelltowerPiece> TowerPieces;

	UPROPERTY(EditInstanceOnly)
	TArray<ASchmellTowerBasePiece> BasePieces;

	UPROPERTY(EditInstanceOnly)
	bool bDebugMove = false;

	UPROPERTY(EditInstanceOnly)
	AEvergreenLifeManager LifeManager;

	bool bIsMoving = false;
	float PreviousHorizontalInput;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LifeManager.LifeComp.OnInteractStartDuringLifeGive.AddUFunction(this, n"FoldOut");
		LifeManager.LifeComp.OnInteractStopDuringLifeGive.AddUFunction(this, n"FoldIn");
		LifeManager.OnNetInteractStartDuringLifeGive.AddUFunction(this, n"OnNetFoldOut");
		LifeManager.OnNetInteractStopDuringLifeGive.AddUFunction(this, n"OnNetFoldIn");

		for(ASchmelltowerPiece Piece : TowerPieces)
		{
			Piece.OnStartMoving.AddUFunction(this, n"OnPieceStartMoving");
			Piece.OnStopMoving.AddUFunction(this, n"OnPieceStopMoving");
		}
	}

	UFUNCTION()
	private void OnPieceStartMoving(ASchmelltowerPiece Piece, bool bIsExtending)
	{
		if(!bIsMoving)
		{
			bIsMoving = true;
			USchmellTowerManagerEffectHandler::Trigger_PlatformsStartMoving(this);
		}
	}

	UFUNCTION()
	private void OnPieceStopMoving(ASchmelltowerPiece Piece, bool bIsExtended)
	{
		if(bIsMoving)
		{
			bIsMoving = false;
			USchmellTowerManagerEffectHandler::Trigger_PlatformsStopMoving(this);
		}

		FSchmellTowerManagerPlatformSectionEffectParams Params;
		Params.Platform = Piece;

		if(bIsExtended)
			USchmellTowerManagerEffectHandler::Trigger_PlatformSectionFullyExtended(this, Params);
		else
			USchmellTowerManagerEffectHandler::Trigger_PlatformSectionFullyRetracted(this, Params);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		for(ASchmellTowerBasePiece Piece : BasePieces)
		{
			Piece.HorizontalInput = HorizontalInput;
		}

		const float Tolerance = 0.08;
		bool bIsZero = Math::IsNearlyZero(HorizontalInput, Tolerance);
		if(bIsZero != Math::IsNearlyZero(PreviousHorizontalInput, Tolerance))
		{
			if(bIsZero)
			{
				USchmellTowerManagerEffectHandler::Trigger_StopRotating(this);
			}
			else
			{
				USchmellTowerManagerEffectHandler::Trigger_StartRotating(this);
			}
		}

		PreviousHorizontalInput = HorizontalInput;
	}

	UFUNCTION()
	void FoldOut()
	{
		for(ASchmelltowerPiece Piece : TowerPieces)
		{
			Piece.TriggerActivatePlatform();
		}

		OnFoldOut();
	}

	UFUNCTION()
	void FoldIn()
	{
		for(ASchmelltowerPiece Piece : TowerPieces)
		{
			Piece.TriggerDeactivatePlatform();
		}

		OnFoldIn();
	}

	UFUNCTION()
	private void OnNetFoldOut()
	{
		for(ASchmelltowerPiece Piece : TowerPieces)
		{
			Piece.OnNetActivatePlatform();
		}
	}

	UFUNCTION()
	private void OnNetFoldIn()
	{
		for(ASchmelltowerPiece Piece : TowerPieces)
		{
			Piece.OnNetDeactivatePlatform();
		}
	}

	UFUNCTION(BlueprintEvent)
	void OnFoldOut() {}

	UFUNCTION(BlueprintEvent)
	void OnFoldIn() {}

	UFUNCTION(BlueprintPure)
	float GetHorizontalInput() const property
	{
		float Input = LifeManager.LifeComp.HorizontalAlpha;
		if(bDebugMove)
			Input = 0.5;

		return Input;
	}
}