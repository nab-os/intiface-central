import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intiface_central/gui_settings_cubit.dart';
import 'package:intiface_central/widget/device_config_widget.dart';
import 'package:intiface_central/device_configuration/user_device_configuration_cubit.dart';
import 'package:intiface_central/widget/device_control_widget.dart';
import 'package:intiface_central/device/device_manager_bloc.dart';
import 'package:intiface_central/engine/engine_control_bloc.dart';

class DevicePage extends StatelessWidget {
  const DevicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EngineControlBloc, EngineControlState>(
        buildWhen: (previous, current) =>
            current is DeviceConnectedState ||
            current is DeviceDisconnectedState ||
            current is ClientDisconnectedState ||
            current is EngineStoppedState,
        builder: (context, engineState) {
          var deviceBloc = context.watch<DeviceManagerBloc>();
          var guiSettingsCubit = context.watch<GuiSettingsCubit>();
          return BlocBuilder<DeviceManagerBloc, DeviceManagerState>(builder: (context, state) {
            List<Widget> deviceWidgets = [];
            List<int> connectedIndexes = [];
            var userDeviceConfigCubit = context.watch<UserDeviceConfigurationCubit>();

            if (engineState is! EngineStoppedState) {
              deviceWidgets.add(const ListTile(title: Text("Connected Devices")));
              for (var deviceCubit in deviceBloc.devices) {
                var device = deviceCubit.device!;
                connectedIndexes.add(device.index);
                var deviceConfig =
                    userDeviceConfigCubit.configs.firstWhere((element) => element.reservedIndex == device.index);
                var expansionName = "device-settings-${device.index}";
                deviceWidgets.add(Card(
                    child: ListView(physics: const NeverScrollableScrollPhysics(), shrinkWrap: true, children: [
                  ListTile(
                    title: Text(device.displayName ?? device.name),
                    subtitle: Text("Index: ${device.index} - Base Name: ${device.name}"),
                  ),
                  DeviceControlWidget(deviceCubit: deviceCubit),
                  BlocBuilder<GuiSettingsCubit, GuiSettingsState>(
                      buildWhen: (previous, current) =>
                          current is GuiSettingStateUpdate && current.valueName == expansionName,
                      builder: (context, state) {
                        return ExpansionPanelList(
                          children: [
                            ExpansionPanel(
                                headerBuilder: (BuildContext context, bool isExpanded) {
                                  return const ListTile(
                                    title: Text("Settings"),
                                  );
                                },
                                body: ListView(
                                    physics: const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    children: [
                                      DeviceConfigWidget(identifier: deviceConfig.identifier),
                                    ]),
                                isExpanded: guiSettingsCubit.getExpansionValue(expansionName) ?? false)
                          ],
                          expansionCallback: (panelIndex, isExpanded) =>
                              guiSettingsCubit.setExpansionValue(expansionName, !isExpanded),
                        );
                      })
                ])));
              }
            }

            deviceWidgets.add(const ListTile(title: Text("Disconnected Devices")));
            for (var deviceConfig in userDeviceConfigCubit.configs) {
              if (connectedIndexes.contains(deviceConfig.reservedIndex)) {
                continue;
              }
              var expansionName = "device-settings-${deviceConfig.reservedIndex}";
              deviceWidgets.add(BlocBuilder<GuiSettingsCubit, GuiSettingsState>(
                  buildWhen: (previous, current) =>
                      current is GuiSettingStateUpdate && current.valueName == expansionName,
                  builder: (context, state) {
                    return ExpansionPanelList(
                        children: [
                          ExpansionPanel(
                              headerBuilder: (BuildContext context, bool isExpanded) {
                                return ListTile(
                                  title: Text(deviceConfig.displayName ?? deviceConfig.name),
                                );
                              },
                              body:
                                  ListView(physics: const NeverScrollableScrollPhysics(), shrinkWrap: true, children: [
                                DeviceConfigWidget(identifier: deviceConfig.identifier),
                              ]),
                              isExpanded: guiSettingsCubit.getExpansionValue(expansionName) ?? true)
                        ],
                        expansionCallback: (panelIndex, isExpanded) =>
                            guiSettingsCubit.setExpansionValue(expansionName, !isExpanded));
                  }));
            }

            return Expanded(
                child: Column(children: [
              Row(
                children: [
                  !deviceBloc.scanning
                      ? TextButton(
                          onPressed: engineState is! EngineStoppedState
                              ? () {
                                  deviceBloc.add(DeviceManagerStartScanningEvent());
                                }
                              : null,
                          child: const Text("Start Scanning"))
                      : TextButton(
                          onPressed: engineState is! EngineStoppedState
                              ? () {
                                  deviceBloc.add(DeviceManagerStopScanningEvent());
                                }
                              : null,
                          child: const Text("Stop Scanning"))
                ],
              ),
              Expanded(
                  child: SingleChildScrollView(
                      child: ListView(
                          physics: const NeverScrollableScrollPhysics(), shrinkWrap: true, children: deviceWidgets)))
            ]));
          });
        });
  }
}
