
UCLASS(Abstract)
class AStencilCutout : AStaticMeshActor 
{
	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;

	UPROPERTY(DefaultComponent)
	UBoxComponent PreviewBox;
	default PreviewBox.bIsEditorOnly = true;
	
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		StaticMeshComponent.SetStaticMesh(Mesh);
		StaticMeshComponent.bRenderInMainPass = false;
		StaticMeshComponent.RenderInDepthPass = false;
		
		PreviewBox.SetWorldTransform(StaticMeshComponent.WorldTransform);
		PreviewBox.BoxExtent = FVector(50, 50, 50);
	}

	UPROPERTY()
	UOutlineDataAsset StencilCutoutAsset;

	UPROPERTY()
	UStaticMesh Mesh;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StencilEffect::ApplyStencilEffect(this.StaticMeshComponent, Game::GetMio(), StencilCutoutAsset, this, EInstigatePriority::Normal);
		StencilEffect::ApplyStencilEffect(this.StaticMeshComponent, Game::GetZoe(), StencilCutoutAsset, this, EInstigatePriority::Normal);
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		
	}
}
