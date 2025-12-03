UCLASS(Abstract)
class ASketchBookPaintCanvas : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent PreviewPlane;

	UPROPERTY()
	UCanvasRenderTarget2D RenderTarget;

	UPROPERTY()
	UMaterialInstanceDynamic Brush;

	UPROPERTY(BlueprintReadOnly)
	bool bDrawing = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
	}

	UFUNCTION()
	void SetEnableDrawing(bool bNewDrawing)
	{
		bDrawing = bNewDrawing;
		Mesh.SetVisibility(true);
	}

	UFUNCTION()
	void DrawPlayer(AHazePlayerCharacter Player, float Size = 2)
	{
		const FVector HalfHeight = FVector(0, 0, Player.ScaledCapsuleHalfHeight);

		FVector EndPos = HalfHeight + Player.GetViewLocation() + (Player.GetActorLocation() - Player.GetViewLocation()) * 500;

		FVector Pos = Math::LinePlaneIntersection(Player.GetActorLocation() + HalfHeight,
												  EndPos,
												  Mesh.WorldLocation,
												  Mesh.UpVector);

		// Remap the world pos to a [0,1] UV coordinate
		auto Bounds = Mesh.GetBounds();

		FVector MaxLocal = Bounds.Box.Max - Bounds.Box.Min;
		FVector PosLocal = Pos - Bounds.Box.Min;
		FVector Ratio = PosLocal / MaxLocal;

		Brush.SetScalarParameterValue(n"Size", Size / 100.0);
		Brush.SetVectorParameterValue(n"Position", FLinearColor(1 - Ratio.Z, Ratio.Y, 0, 0));
	}
};
