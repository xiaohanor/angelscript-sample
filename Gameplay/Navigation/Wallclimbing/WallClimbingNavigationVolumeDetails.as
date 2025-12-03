#if EDITOR
class UWallClimbingNavigationVolumeDetails : UHazeScriptDetailCustomization
{
	default DetailClass = AWallclimbingNavigationVolume;

	UHazeImmediateDrawer Drawer;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		auto Volume = Cast<AWallclimbingNavigationVolume>(GetCustomizedObject());
		if (Volume == nullptr)
			return;

		Drawer = AddImmediateRow(n"Navigation");
		HideCategory(n"NavigationInternalData");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		auto Volume = Cast<AWallclimbingNavigationVolume>(GetCustomizedObject());
		if (Volume == nullptr)
			return;

		if (Drawer != nullptr && Drawer.IsVisible())
		{
			auto Root = Drawer.Begin();
			Root.Text(f"NavMesh Faces: {Volume.NavMesh.Num()}");
			Root.Text(f"Hashed Polys: {Volume.HashedNavMeshPolys.Num()}");
			Root.Text(f"Memory Size: {float(Volume.GetNavigationMemoryUsageBytes()) / 1024.0 / 1024.0 :.2f} MiB");
			Drawer.End();
		}
	}
}
#endif