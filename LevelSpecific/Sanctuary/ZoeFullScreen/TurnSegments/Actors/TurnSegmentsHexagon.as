UCLASS(Abstract)
class ATurnSegmentsHexagon : ATurnSegmentsActor
{
	UPROPERTY(DefaultComponent, Attach = "Root")
    UStaticMeshComponent TopMesh;

	UPROPERTY(DefaultComponent, Attach = "Root")
    UStaticMeshComponent RightUpMesh;

	UPROPERTY(DefaultComponent, Attach = "Root")
    UStaticMeshComponent RightDownMesh;

	UPROPERTY(DefaultComponent, Attach = "Root")
    UStaticMeshComponent BottomMesh;

	UPROPERTY(DefaultComponent, Attach = "Root")
    UStaticMeshComponent LeftDownMesh;

	UPROPERTY(DefaultComponent, Attach = "Root")
    UStaticMeshComponent LeftUpMesh;

    void SetMaterial(UMaterial Material) override
    {
		TopMesh.SetMaterial(0, Material);
		RightUpMesh.SetMaterial(0, Material);
		RightDownMesh.SetMaterial(0, Material);
		BottomMesh.SetMaterial(0, Material);
		LeftDownMesh.SetMaterial(0, Material);
		LeftUpMesh.SetMaterial(0, Material);
    }
}