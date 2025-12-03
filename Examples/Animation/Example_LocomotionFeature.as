/*
 * In Unreal we store most animations in Data Assets.
 * These Data Assets are built from a class similar to what you can see below.
 * 
 * A SubABP can then get this class/data asset and read all of the data from it
 *
 * To make a data asset based on this class in Unreal Engine:
 * Right click in the content browser: Miscellaneous > Data Asset
 * Search & select the class, in this case 'LocomotionFeatureExample'
 *
 * All LocomotionFeature data assets should be saved somewhere under: 
 * Content/Blueprints/Animation/LocomotionFeatureAssets/
 */
 

/*
 * This struct should contain all of the animaton data
 * The name of the struct should always start with 'FLocomotionFeature'
 * And the name should have the suffix 'Data'
 */
struct FLocomotionFeatureExampleAnimData
{

    /*
	 * Every variable needs to have UPROPERTY() written above it
	 * for the variable to be visible in the unreal data asset.
	 * 
	 * You can spesify a category in the UPROPERTY() with 'Category = "My Category"'
	 */
	UPROPERTY(Category = "Animations")
    FHazePlaySequenceData Idle;

	/*
	 * You can create sub-categories by adding a |
	 */
	UPROPERTY(Category = "Animations|Movement")
    FHazePlayBlendSpaceData MovementBlendSpace;

	/*
	 * By adding 'BlueprintReadOnly' in the UPROPERTY() the
	 * variable cannot be edited from within the ABP, only read.
	 * 
	 * You can assign a default value to a variable by adding '= <VALUE>;'
	 */
	UPROPERTY(BlueprintReadOnly, Category = "Settings")
    float CustomFloat = 5.0;
    
}


/*
 * This class is what will be used to create the Data Asset in Unreal.
 * 
 * The name of the class should always start with 'ULocomotionFeature'
 * and then be followed by the name of the feature.
 * 
 * It should also always inherit from the 'UHazeLocomotionFeatureBase' class
 */

class ULocomotionFeatureExample : UHazeLocomotionFeatureBase
{

	/*
	 * The Tag is used to identify this spesific feature.
	 * E.g. if a programmer now calls the tag "Example" this
	 * feature will be activated.
	 */
	default Tag = n"Example";

	/*
	 * Add the struct we created above.
	 * By adding 'meta = (ShowOnlyInnerProperties)' we make sure 
	 * everything isn't hidden under a property called 'FeatureData'.
	 * Instead the categories added in the struct will work as expected.
	 */
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
    FLocomotionFeatureExampleAnimData AnimData;

}