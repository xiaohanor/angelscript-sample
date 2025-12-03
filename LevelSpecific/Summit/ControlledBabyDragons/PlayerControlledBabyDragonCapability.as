
class UPlayerControlledBabyDragonCapability : UHazePlayerCapability
{
	UPlayerControlledBabyDragonComponent DragonComp;

	USkeletalMesh PreviousMesh;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerControlledBabyDragonComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PreviousMesh = Player.Mesh.GetSkeletalMeshAsset();
		Player.Mesh.SetSkeletalMeshAsset(DragonComp.BabyDragonMesh);
		Player.Mesh.SetRelativeLocation(DragonComp.MeshOffset);
		Player.Mesh.SetRelativeScale3D(DragonComp.MeshScale);
		Player.ApplyCameraSettings(DragonComp.CameraSettings, 2, this, SubPriority = 52);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.Mesh.SetSkeletalMeshAsset(PreviousMesh);
		Player.Mesh.SetRelativeLocation(FVector::ZeroVector);
		Player.Mesh.SetRelativeScale3D(FVector::OneVector);
		Player.ClearCameraSettingsByInstigator(this);
	}
};