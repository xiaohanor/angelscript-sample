UCLASS(Abstract)
class ATurnSegmentsBox : ATurnSegmentsActor
{
	UPROPERTY(DefaultComponent, Attach = "Root")
    UStaticMeshComponent TopMesh;

	UPROPERTY(DefaultComponent, Attach = "Root")
    UStaticMeshComponent RightMesh;

	UPROPERTY(DefaultComponent, Attach = "Root")
    UStaticMeshComponent BottomMesh;

	UPROPERTY(DefaultComponent, Attach = "Root")
    UStaticMeshComponent LeftMesh;

    void SetMaterial(UMaterial Material) override
    {
		TopMesh.SetMaterial(0, Material);
		RightMesh.SetMaterial(0, Material);
		BottomMesh.SetMaterial(0, Material);
		LeftMesh.SetMaterial(0, Material);
    }
}