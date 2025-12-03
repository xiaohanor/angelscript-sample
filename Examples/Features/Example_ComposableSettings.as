
/*
  Using composable settings automatically lets multiple data assets be
  combined into one settings object using checkboxes and priorities.
*/
class UExampleComposableSettings : UHazeComposableSettings
{
	UPROPERTY()
	float SomeFloatValue = 5.0;

	UPROPERTY()
	FName SomeNameValue;

	UPROPERTY()
	bool bSomeBoolValue;
};

void Example_ComposableSettings(UExampleComposableSettings SettingsToApply)
{
	/* 
		We can get the composable settings object for an actor by calling
		the static function to return it:
	*/
	AHazePlayerCharacter Player = Game::Mio;
	UExampleComposableSettings ExampleSettings = UExampleComposableSettings::GetSettings(Player);

	check(ExampleSettings.SomeFloatValue == 4.0);

	// We can apply a new data asset as settings for this type
	Player.ApplySettings(SettingsToApply, Instigator = Player);

	// After we apply new settings to it, the settings object we retrieved earlier will immediately be updated
	if (SettingsToApply.bOverride_SomeFloatValue)
		check(ExampleSettings.SomeFloatValue == SettingsToApply.SomeFloatValue);

	// Clearing the settings set by an instigator is also possible
	Player.ClearSettingsByInstigator(Instigator = Player);
	// Player.ClearSettingsWithAsset(SettingsToApply, Instigator = Player);
	// Player.ClearSettingsOfClass(UExampleComposableSettings, Instigator = Player);
}

/* If we want to override a specific parameter instead of applying a data asset, we can use the transient settings for it. */
void Example_OverrideComposableSetting()
{
	AHazePlayerCharacter Player = Game::Mio;
	UExampleComposableSettings::SetSomeFloatValue(Player, 8.0, Instigator = Player);
	auto CurrentSettings = UExampleComposableSettings::GetSettings(Player);
	check(CurrentSettings.SomeFloatValue == 8.0);
}

/* Clearing it works by resetting the override bool. */
void Example_ClearOverrideSetting()
{
	AHazePlayerCharacter Player = Game::Mio;
	UExampleComposableSettings::ClearSomeFloatValue(Player, Instigator = Player);
	auto CurrentSettings = UExampleComposableSettings::GetSettings(Player);
	check(CurrentSettings.SomeFloatValue == 5.0);
}

/*
	When using structs in a composable asset, both the struct
	and the UPROPERTY using the struct need the ComposedStruct 
	Meta tag, so it knows to create bools inside the struct.
*/
USTRUCT(Meta = (ComposedStruct))
struct FExampleComposedStruct
{
	UPROPERTY()
	float SubValueOne = 5.0;
	UPROPERTY()
	float SubValueTwo = 5.0;
};

class UExampleComposedStructSettings : UHazeComposableSettings
{
	UPROPERTY(Meta = (ComposedStruct))
	FExampleComposedStruct InnerValues;
};

/* It's possible to create a data asset that composes
   onto a *different* data asset. This is useful to create
   sub-data-assets that can only ever override a subset
   of properties.

   Every property in the sub asset should exist and be named the same
   in the base asset that is being composed onto.
*/

UCLASS(Meta = (ComposeSettingsOnto = "UExampleComposableSettings"))
class UExampleSubComposableSettings : UHazeComposableSettings
{
	UPROPERTY()
	FName SomeNameValue;
};

/* You can declare a scripted settings asset using the 'asset' keyword.
   These are not editable from the editor, but can be used as convenient defaults.
*/
asset ExampleDefaultSettings of UExampleComposableSettings
{
	SomeFloatValue = 10.0;
	SomeNameValue = n"AName";
}

class AExampleDefaultSettingsActor : AHazeActor
{
	UPROPERTY()
	UExampleComposableSettings DefaultSettings = ExampleDefaultSettings;

	UExampleComposableSettings Settings;

	TArray<TSubclassOf<UHazeCapability>> TEST;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Default settings can be applied to the actor like this:
		ApplyDefaultSettings(DefaultSettings);

		// We can retrieve the final applied settings asset the same as before
		Settings = UExampleComposableSettings::GetSettings(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// The applied settings will have either the default, or
		// whatever overrides have been applied on top of it:
		Print("Applied: "+Settings.SomeFloatValue);
		// We can also read from our default asset to get the original values
		Print("Default: "+DefaultSettings.SomeFloatValue);
	}
}